import AppKit

/// 独立的键盘盲打嗅探服务（Service Layer）
///
/// 职责单一：拦截面板上尚未被任何输入框消费的键盘事件，
/// 将原始字符代理给上层，由上层决定是否消费并切换焦点。
///
/// ⚠️ 与 SwiftUI View 完全解耦，不持有任何 View/ViewModel 引用。
/// ⚠️ 必须在主线程调用 start()/stop()，生命周期由调用方管理。
@MainActor
final class TypeToSearchService {

    static let shared = TypeToSearchService()

    // MARK: - 外部同步的状态

    /// 由上层控制：当存在带有文本输入的二级窗口/面板时置 true，
    /// 此时所有按键直接放行，不执行任何拦截和强制聚焦操作。
    var isPaused: Bool = false

    /// 由 View 层实时同步：当搜索框获得焦点时置 true，
    /// 此时所有按键直接放行给 TextField 原生处理。
    var isTextFieldFocused: Bool = false

    // MARK: - 回调

    /// 代理给上层的键盘事件，返回 true 表示上层已消费该事件。
    var onInterceptedKey: ((NSEvent) -> Bool)?

    // MARK: - 内部状态

    private var localMonitor: Any?

    // MARK: - 生命周期

    func start() {
        guard localMonitor == nil else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleKeyDown(event)
        }
    }

    func stop() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    // MARK: - 核心拦截逻辑

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        // 0. 休眠状态 → 所有按键原封不动还给系统（编辑窗口等二级面板场景）
        if isPaused { return event }

        // 1. 搜索框已聚焦 → 全部放行，由 TextField 原生消费
        if isTextFieldFocused { return event }

        // 2. Command / Option / Control 组合键直接放行，保留给现有快捷键和系统处理。
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers.contains(.command) || modifiers.contains(.option) || modifiers.contains(.control) {
            return event
        }

        // 3. 提取用户真实可见字符；无字符时交还系统（方向键等仍可能是私有 function key 标量）。
        guard let chars = event.characters, !chars.isEmpty else {
            return event
        }

        // 4. 是否消费完全交给上层决定；服务层不承担任何业务判断。
        let isHandled = onInterceptedKey?(event) ?? false
        return isHandled ? nil : event
    }
}

import AppKit
import Foundation
import SwiftData
import KeyboardShortcuts
import Combine

@MainActor
final class SnippetShortcutManager {
    static let shared = SnippetShortcutManager()

    private let container: ModelContainer
    private var registeredShortcuts = Set<String>()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.container = ClipboardRuntimeStore.shared.container

        // 1. 订阅数据库变更通知，一旦数据发生增删改，自动刷新快捷键监听
        NotificationCenter.default.publisher(for: .clipboardRecordDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshShortcuts()
            }
            .store(in: &cancellables)

        // 2. 订阅 KeyboardShortcuts 的快捷键变更通知。
        // 一旦在 UI 上进行了快捷键绑定录入或清除，自动同步并更新 SwiftData 中的状态。
        let shortcutDidChangeNotification = Notification.Name("KeyboardShortcuts_shortcutByNameDidChange")
        NotificationCenter.default.publisher(for: shortcutDidChangeNotification)
            .receive(on: RunLoop.main)
            .compactMap { $0.userInfo?["name"] as? KeyboardShortcuts.Name }
            .filter { $0.rawValue.hasPrefix("snippet_") }
            .sink { [weak self] name in
                Task { @MainActor [weak self] in
                    self?.syncShortcutChangeToDatabase(name: name)
                }
            }
            .store(in: &cancellables)
    }

    /// 启动快捷键监听服务
    func start() {
        refreshShortcuts()
    }

    /// 刷新并更新所有已绑定的快捷键监听
    func refreshShortcuts() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<ClipboardRecord>(
            predicate: #Predicate<ClipboardRecord> { $0.isSnippet == true && $0.shortcutName != nil }
        )

        guard let records = try? context.fetch(descriptor) else { return }

        // 筛选出有效的快捷键标识符
        let activeSnippets = records.filter { record in
            if let name = record.shortcutName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            return false
        }

        let activeNames = Set(activeSnippets.compactMap { $0.shortcutName })

        // 1. 注销已被删除或已解绑的快捷键
        let toDeRegister = registeredShortcuts.subtracting(activeNames)
        for nameStr in toDeRegister {
            let nsName = KeyboardShortcuts.Name(nameStr)
            KeyboardShortcuts.reset(nsName)
            KeyboardShortcuts.disable([nsName])
            registeredShortcuts.remove(nameStr)
            print("ℹ️ [SnippetShortcutManager] 已注销全局快捷键: \(nameStr)")
        }

        // 2. 注册新绑定的快捷键
        let toRegister = activeNames.subtracting(registeredShortcuts)
        for nameStr in toRegister {
            let nsName = KeyboardShortcuts.Name(nameStr)

            KeyboardShortcuts.onKeyDown(for: nsName) { [weak self] in
                self?.handleShortcutTrigger(shortcutName: nameStr)
            }
            KeyboardShortcuts.enable([nsName])
            registeredShortcuts.insert(nameStr)
            print("ℹ️ [SnippetShortcutManager] 已注册全局快捷键: \(nameStr)")
        }
    }

    /// 将 UI 录入的快捷键变动同步写入 SwiftData
    private func syncShortcutChangeToDatabase(name: KeyboardShortcuts.Name) {
        let rawValue = name.rawValue
        let prefix = "snippet_"
        guard rawValue.hasPrefix(prefix) else { return }

        let uuidStr = String(rawValue.dropFirst(prefix.count))
        guard let uuid = UUID(uuidString: uuidStr) else { return }

        let context = container.mainContext
        let descriptor = FetchDescriptor<ClipboardRecord>(
            predicate: #Predicate<ClipboardRecord> { $0.id == uuid }
        )

        guard let record = try? context.fetch(descriptor).first else { return }

        let shortcut = name.shortcut
        let hasShortcut = shortcut != nil

        let newShortcutName = hasShortcut ? rawValue : nil
        let newIsSnippet = hasShortcut

        if record.shortcutName != newShortcutName || record.isSnippet != newIsSnippet {
            record.shortcutName = newShortcutName
            record.isSnippet = newIsSnippet

            do {
                try context.save()
                print("✅ [SnippetShortcutManager] 成功将快捷键变动同步入库: \(rawValue), isSnippet: \(newIsSnippet)")
                // 广播通知，拉起刷新
                NotificationCenter.default.post(
                    name: .clipboardRecordDidChange,
                    object: nil,
                    userInfo: [
                        "contentHash": record.contentHash,
                        "kind": ClipboardRecordChangeKind.content.rawValue
                    ]
                )
            } catch {
                print("❌ [SnippetShortcutManager] 保存快捷键同步失败: \(error)")
            }
        }
    }

    /// 全局快捷键响应回调，安全查库并静默粘贴
    private func handleShortcutTrigger(shortcutName: String) {
        let context = container.mainContext
        let descriptor = FetchDescriptor<ClipboardRecord>(
            predicate: #Predicate<ClipboardRecord> { $0.shortcutName == shortcutName }
        )

        guard let record = try? context.fetch(descriptor).first else {
            print("⚠️ [SnippetShortcutManager] 未找到对应快捷键记录: \(shortcutName)")
            return
        }

        let pasteRecord = ClipboardPasteRecord(
            id: record.id,
            typeRawValue: record.typeRawValue,
            plainText: record.plainText,
            rtfData: record.rtfData,
            richTextArchiveData: record.richTextArchiveData
        )

        Task {
            // 后台静默执行粘贴，无需唤起面板
            await PasteEngine.shared.paste(record: pasteRecord)
        }
    }
}

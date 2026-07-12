import AppKit
import Foundation

/// 管理图片编辑流程：拷贝原图到临时目录 → 系统 Preview.app Markup → 监听保存 → 回调 ViewModel 创建新记录。
/// ⚠️ 架构红线：绝不修改原图，编辑结果作为全新剪贴板记录入库。
@MainActor
final class ImageEditWindowManager {
    static let shared = ImageEditWindowManager()

    /// 当前正在编辑的会话 [tempURL: EditSession]
    private var activeSessions: [URL: EditSession] = [:]

    private init() {}

    struct EditSession {
        let tempURL: URL
        let originalItem: ClipboardItem
        let fileDescriptor: Int32
        let dispatchSource: DispatchSourceFileSystemObject
        /// 原始文件大小，用于判断是否真正修改过
        let originalFileSize: UInt64
    }

    // MARK: - Public API

    /// 由 ViewModel 调用：准备临时文件并打开系统编辑器
    func openEditor(tempURL: URL, originalItem: ClipboardItem, viewModel: ClipboardViewModel) {
        // 防止重复打开同一图片
        if activeSessions[tempURL] != nil {
            NSWorkspace.shared.open(tempURL)
            return
        }

        // 记录原始文件大小
        let originalFileSize = (try? FileManager.default.attributesOfItem(atPath: tempURL.path)[.size] as? UInt64) ?? 0

        // 启动文件监控（监听 Preview.app 写入）
        let fd = open(tempURL.path, O_EVTONLY)
        guard fd >= 0 else {
            print("❌ [ImageEditWindowManager] 无法打开文件描述符: \(tempURL.path)")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .main
        )

        let session = EditSession(
            tempURL: tempURL,
            originalItem: originalItem,
            fileDescriptor: fd,
            dispatchSource: source,
            originalFileSize: originalFileSize
        )
        activeSessions[tempURL] = session

        source.setEventHandler { [weak self] in
            self?.handleFileChanged(tempURL: tempURL, viewModel: viewModel)
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()

        // 用系统 Preview.app 打开（自带 Markup 编辑）
        NSWorkspace.shared.open(tempURL)
    }

    // MARK: - Private

    private func handleFileChanged(tempURL: URL, viewModel: ClipboardViewModel) {
        guard let session = activeSessions[tempURL] else { return }

        // 检查文件是否真正被修改（大小变化）
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: tempURL.path),
              let newSize = attrs[.size] as? UInt64,
              newSize != session.originalFileSize,
              newSize > 0 else {
            return
        }

        // 防止重复触发：文件写入可能产生多次事件，取消监听后再处理
        session.dispatchSource.cancel()
        activeSessions.removeValue(forKey: tempURL)

        // 延迟读取，等 Preview.app 完成写入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.saveEditedImage(tempURL: tempURL, originalItem: session.originalItem)
        }
    }

    /// 清理所有活跃会话（App 退出时调用）
    func cleanup() {
        for (_, session) in activeSessions {
            session.dispatchSource.cancel()
        }
        activeSessions.removeAll()
    }
}

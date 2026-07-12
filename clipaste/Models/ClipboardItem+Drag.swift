import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ClipboardDragType {
    static let item = "com.seedpilot.clipboard.item"
    static let group = "com.seedpilot.clipboard.group"
}

extension ClipboardItem {
    var universalDragProvider: NSItemProvider {
        let provider: NSItemProvider
        let plainText = rawText ?? (textPreview.isEmpty ? nil : textPreview)

        // ==========================================
        // 1. 本地文件（⚠️ 必须最高优先级，否则会被纯文本分支拦截）
        // ==========================================
        if contentType == .fileURL, let fileURL = resolvedFileURL {
            provider = NSItemProvider(object: fileURL as NSURL)

        // ==========================================
        // 2. 图片
        // ==========================================
        } else if contentType == .image {
            provider = NSItemProvider()
            let typeIdentifier = imageUTType ?? UTType.png.identifier
            provider.registerDataRepresentation(
                forTypeIdentifier: typeIdentifier,
                visibility: .all
            ) { [id] completion in
                Task {
                    let imageData = await StorageManager.shared.loadImageData(id: id)
                    let previewData = await StorageManager.shared.loadPreviewImageData(id: id)
                    let data = imageData ?? previewData
                    completion(data, nil)
                }
                return nil
            }

        // ==========================================
        // 3. 超链接
        // ==========================================
        } else if isFastLink,
                  let text = plainText,
                  let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
            provider = NSItemProvider(object: url as NSURL)
            provider.registerObject(text as NSString, visibility: .all)

        // ==========================================
        // 4. 纯文本
        // ==========================================
        } else if let text = plainText {
            provider = NSItemProvider(object: text as NSString)
        } else {
            provider = NSItemProvider()
        }

        // ==========================================
        // 5. 内部识别码（用于分组拖拽）
        // ==========================================
        provider.registerDataRepresentation(
            forTypeIdentifier: ClipboardDragType.item,
            visibility: .all
        ) { [id] completion in
            completion(id.uuidString.data(using: .utf8), nil)
            return nil
        }

        return provider
    }
}

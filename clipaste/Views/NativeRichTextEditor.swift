import SwiftUI
import AppKit

/// NSTextView-backed rich text editor with native Inspector Bar (formatting toolbar).
/// ⚠️ Context Extract 模式：NSTextView 内部状态绝不实时回传给 SwiftUI。
/// 只有保存时通过 EditorContext 闭包一次性提取数据。
struct NativeRichTextEditor: NSViewRepresentable {
    let initialText: NSAttributedString
    let context: EditorContext

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        // ⚠️ 必须在这里捕获：因为参数 context 会遮蔽 self.context（EditorContext）
        let editorContext = self.context

        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        // 基础编辑配置
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = NSColor.textColor
        textView.textContainerInset = NSSize(width: 16, height: 16)

        // 召唤原生高级检查器栏
        textView.usesInspectorBar = true
        // ⚠️ 极其核心：必须授权使用字体面板，否则 Inspector Bar 的加粗/斜体指令会被 NSTextView 物理丢弃
        textView.usesFontPanel = true
        textView.usesRuler = true // 开启标尺与段落对齐支持

        // 非连续布局：支持大文本
        textView.layoutManager?.allowsNonContiguousLayout = true

        // 注入初始文本（一次性，绝不双向同步）
        textView.textStorage?.setAttributedString(initialText)

        // ⚠️ 上下文提权：只有在点击保存时，才会执行这些闭包提取数据，平时绝对不干扰主线程
        editorContext.getRTFData = { [weak textView] in
            guard let tv = textView else { return nil }
            let range = NSRange(location: 0, length: tv.attributedString().length)
            return try? tv.attributedString().data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        }

        editorContext.getPlainText = { [weak textView] in
            return textView?.string ?? ""
        }

        editorContext.applyPlainText = { [weak textView] in
            guard let tv = textView else { return }
            let plain = tv.string
            let attr = NSAttributedString(string: plain, attributes: [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.textColor
            ])
            tv.textStorage?.setAttributedString(attr)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // ⚠️ 物理隔离：不再从 SwiftUI 侧同步任何状态到 NSTextView
        // NSTextView 是唯一的编辑真相源，SwiftUI 不再参与编辑生命周期
    }

    class Coordinator: NSObject {
        // ⚠️ 极其核心：Coordinator 不再持有 parent 引用，不再实现 NSTextStorageDelegate
        // 彻底切断 NSTextView → SwiftUI 的实时回传通道
    }
}

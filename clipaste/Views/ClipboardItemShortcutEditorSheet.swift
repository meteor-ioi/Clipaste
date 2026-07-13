import SwiftUI
import KeyboardShortcuts

struct ClipboardItemShortcutEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: ClipboardItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置常用语快捷键")
                .font(.title3.weight(.semibold))

            Text(previewText)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)

            HStack {
                Text("全局快捷键:")
                    .font(.system(size: 13))
                Spacer()

                ShortcutRecorderRow("", name: KeyboardShortcuts.Name("snippet_\(item.id.uuidString)"))
                    .frame(width: 160)
            }

            HStack(spacing: 12) {
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private var previewText: String {
        if let customTitle = item.customTitle {
            return customTitle
        }
        if let linkTitle = item.linkTitle {
            return "🔗 " + linkTitle
        }

        switch item.contentType {
        case .image:
            return "🖼️ " + String(localized: "Smart Filter Image")
        case .fileURL:
            if let path = item.rawText, let url = URL(string: path) {
                return "📄 " + url.lastPathComponent
            }
            return "📄 " + String(localized: "Smart Filter File")
        case .color:
            return "🎨 " + (item.rawText ?? String(localized: "Smart Filter Color"))
        case .code:
            let content = item.rawText?.prefix(40) ?? ""
            return "💻 " + content.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            let content = item.rawText?.prefix(40) ?? ""
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

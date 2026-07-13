import KeyboardShortcuts
import SwiftUI
import SwiftData

struct ShortcutsSettingsView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel

    @Query(filter: #Predicate<ClipboardGroupModel> { $0.deletedAt == nil }, sort: \ClipboardGroupModel.sortOrder)
    private var groups: [ClipboardGroupModel]

    @Query(sort: \ClipboardRecord.timestamp, order: .reverse)
    private var allRecords: [ClipboardRecord]

    @State private var selectedGroupID: String = ""

    init() {}

    var body: some View {
        Form {
            globalShortcutsSection
            panelShortcutsSection
            modifiersSection
            snippetShortcutsSection
            resetSection
        }
        .settingsPageChrome()
    }
}

// MARK: - Section 1: Global Shortcuts

private extension ShortcutsSettingsView {
    var globalShortcutsSection: some View {
        Section {
            ShortcutRecorderRow("Show / Hide Clipboard Panel", name: .toggleClipboardPanel)
        } header: {
            SettingsSectionHeader(title: "Global Shortcuts")
        }
    }
}

// MARK: - Section 2: Panel Shortcuts

private extension ShortcutsSettingsView {
    var panelShortcutsSection: some View {
        Section {
            ShortcutRecorderRow("Toggle Vertical Clipboard", name: .toggleVerticalClipboard)
            ShortcutRecorderRow("Next List", name: .nextList)
            ShortcutRecorderRow("Previous List", name: .prevList)
            ShortcutRecorderRow("Toggle Favorites for Selection", name: .toggleFavoriteSelection)
            ShortcutRecorderRow("Clear Clipboard History", name: .clearHistory)
        } header: {
            SettingsSectionHeader(title: "Panel Shortcuts")
        }
    }
}

// MARK: - Section 3: Modifier Keys

private extension ShortcutsSettingsView {
    var modifiersSection: some View {
        Section {
            ModifierPickerView(
                title: "Quick Paste",
                suffix: "+ 1…9",
                selection: $viewModel.quickPasteModifier,
                excludedOption: viewModel.plainTextModifier
            )

            ModifierPickerView(
                title: "Plain Text Modifier",
                suffix: "",
                selection: $viewModel.plainTextModifier,
                excludedOption: viewModel.quickPasteModifier
            )
        } header: {
            SettingsSectionHeader(title: "Modifier Keys")
        } footer: {
            SettingsSectionFooter {
                Text("Within the clipboard panel, hold the quick paste modifier to reveal 1…9 shortcuts. Add the plain text modifier while copying, pressing Return to paste, or using quick paste to strip formatting.")
            }
        }
    }
}

// MARK: - Section 4: Reset

private extension ShortcutsSettingsView {
    var resetSection: some View {
        Section {
            Button {
                KeyboardShortcuts.reset(
                    .toggleClipboardPanel,
                    .toggleVerticalClipboard,
                    .nextList,
                    .prevList,
                    .toggleFavoriteSelection,
                    .clearHistory
                )
            } label: {
                Label("Reset Shortcuts to Defaults", systemImage: "arrow.counterclockwise")
            }
        }
    }
}

// MARK: - Shortcut Recorder Row

struct ShortcutRecorderRow: View {
    let title: LocalizedStringKey
    @StateObject private var viewModel: ShortcutRecorderRowViewModel

    init(_ title: LocalizedStringKey, name: KeyboardShortcuts.Name) {
        self.title = title
        _viewModel = StateObject(wrappedValue: ShortcutRecorderRowViewModel(name: name))
    }

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                shortcutRecorder

                if name.defaultShortcut != nil {
                    Button("Restore Default Shortcut", systemImage: "arrow.uturn.backward") {
                        viewModel.restoreDefault()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .disabled(!viewModel.canRestoreDefault)
                }
            }
        }
    }

    private var shortcutRecorder: some View {
        LocalizedShortcutRecorder(viewModel: viewModel)
    }

    private var name: KeyboardShortcuts.Name {
        viewModel.name
    }
}

// MARK: - Section 3.5: Snippet Shortcuts

private extension ShortcutsSettingsView {
    var snippetShortcutsSection: some View {
        Section {
            Picker("选择常用语分组", selection: $selectedGroupID) {
                Text("请选择分组...").tag("")
                ForEach(groups) { group in
                    Label(group.name, systemImage: group.resolvedSystemIconName ?? "folder")
                        .tag(group.id)
                }
            }
            .pickerStyle(.menu)

            if !selectedGroupID.isEmpty {
                let records = groupRecords
                if records.isEmpty {
                    Text("当前分组下暂无任何剪贴板条目。 请在剪贴板历史主面板中，右击条目 -> 分配至该分组。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(records) { record in
                            SnippetShortcutRow(record: record)
                            if record.id != records.last?.id {
                                Divider()
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        } header: {
            SettingsSectionHeader(title: "常用语粘贴快捷键")
        } footer: {
            SettingsSectionFooter {
                Text("为此常用语分组内的条目指定全局快捷键。在任何输入框中按下对应快捷键，即可静默粘贴该条目的内容。")
            }
        }
        .onAppear {
            if selectedGroupID.isEmpty, let first = groups.first {
                selectedGroupID = first.id
            }
        }
        .onChange(of: groups) { _, newGroups in
            if selectedGroupID.isEmpty || !newGroups.contains(where: { $0.id == selectedGroupID }) {
                selectedGroupID = newGroups.first?.id ?? ""
            }
        }
    }

    var groupRecords: [ClipboardRecord] {
        guard !selectedGroupID.isEmpty else { return [] }
        return allRecords.filter { record in
            if record.groupId == selectedGroupID { return true }
            if let raw = record.groupIdsRaw, raw.contains(selectedGroupID) { return true }
            return false
        }
    }
}

// MARK: - Snippet Shortcut Row Component

struct SnippetShortcutRow: View {
    let record: ClipboardRecord

    var body: some View {
        HStack {
            // 左侧内容缩略
            Text(previewText)
                .lineLimit(1)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // 中间分类
            Text(typeBadgeText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(4)
                .frame(width: 50)

            // 右侧录入组件
            ShortcutRecorderRow("", name: KeyboardShortcuts.Name("snippet_\(record.id.uuidString)"))
                .frame(width: 150)
        }
        .padding(.vertical, 2)
    }

    private var previewText: String {
        if let customTitle = record.customTitle {
            return customTitle
        }
        if let linkTitle = record.linkTitle {
            return "🔗 " + linkTitle
        }

        switch ClipboardContentType(rawValue: record.typeRawValue) ?? .text {
        case .image:
            return "🖼️ " + String(localized: "Smart Filter Image")
        case .fileURL:
            if let path = record.plainText, let url = URL(string: path) {
                return "📄 " + url.lastPathComponent
            }
            return "📄 " + String(localized: "Smart Filter File")
        case .color:
            return "🎨 " + (record.plainText ?? String(localized: "Smart Filter Color"))
        case .code:
            let content = record.plainText?.prefix(40) ?? ""
            return "💻 " + content.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            let content = record.plainText?.prefix(40) ?? ""
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private var typeBadgeText: String {
        switch ClipboardContentType(rawValue: record.typeRawValue) ?? .text {
        case .text: return "文本"
        case .image: return "图片"
        case .fileURL: return "文件"
        case .color: return "颜色"
        case .link: return "链接"
        case .code: return "代码"
        }
    }
}

#Preview {
    ShortcutsSettingsView()
        .environmentObject(SettingsViewModel())
}

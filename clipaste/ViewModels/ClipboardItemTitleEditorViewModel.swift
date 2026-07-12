import Foundation
import Observation

@MainActor
@Observable
final class ClipboardItemTitleEditorViewModel {
    let itemID: UUID
    let originalTitle: String?

    var draftTitle: String

    init(item: ClipboardItem) {
        self.itemID = item.id
        self.originalTitle = item.trimmedCustomTitle
        self.draftTitle = item.trimmedCustomTitle ?? ""
    }

    var sheetTitle: LocalizedStringResource {
        originalTitle == nil ? "Add Title" : "Edit Title"
    }

    var normalizedTitle: String? {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var canSave: Bool {
        normalizedTitle != originalTitle
    }
}

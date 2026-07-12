import SwiftUI

struct HighlightedText: View {
    let text: String
    let highlight: String
    var font: Font = .system(size: 13, weight: .regular)
    var foregroundColor: Color = .primary
    var highlightBackgroundColor: Color = .yellow.opacity(0.8)
    var highlightForegroundColor: Color = .black
    var highlightFont: Font? = nil

    var body: some View {
        Text(attributedString)
    }

    private var attributedString: AttributedString {
        var attrString = AttributedString(text)
        attrString.font = font
        attrString.foregroundColor = foregroundColor

        let query = highlight.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return attrString }

        let lowercasedText = text.lowercased()
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
        let emphasizedFont = highlightFont ?? font.bold()

        while let matchRange = lowercasedText.range(of: query, range: searchRange) {
            if let attributedRange = Range(matchRange, in: attrString) {
                attrString[attributedRange].backgroundColor = highlightBackgroundColor
                attrString[attributedRange].foregroundColor = highlightForegroundColor
                attrString[attributedRange].font = emphasizedFont
            }

            searchRange = matchRange.upperBound..<lowercasedText.endIndex
        }

        return attrString
    }
}

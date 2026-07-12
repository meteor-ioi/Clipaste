import SwiftUI
#if os(macOS)
import AppKit
#endif

struct GroupIconView: View {
    let iconName: String?
    var size: CGFloat = 14

    var body: some View {
        if let iconName = ClipboardGroupIconName.normalize(iconName) {
            if IconPickerViewModel.customIconNames.contains(iconName) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            }
        }
    }
}

struct GroupMenuLabel: View {
    let title: String
    let iconName: String?

    var body: some View {
        Label {
            Text(verbatim: title)
        } icon: {
            GroupMenuIcon(iconName: iconName, size: 13)
        }
    }
}

private struct GroupMenuIcon: View {
    let iconName: String?
    var size: CGFloat

    var body: some View {
        if let iconName = ClipboardGroupIconName.normalize(iconName) {
            if IconPickerViewModel.customIconNames.contains(iconName) {
                #if os(macOS)
                if let image = Self.sizedTemplateImage(named: iconName, size: size) {
                    Image(nsImage: image)
                }
                #else
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                #endif
            } else {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            }
        }
    }

    #if os(macOS)
    private static func sizedTemplateImage(named: String, size: CGFloat) -> NSImage? {
        guard let original = NSImage(named: named) else { return nil }
        guard let copy = original.copy() as? NSImage else { return nil }
        copy.size = NSSize(width: size, height: size)
        copy.isTemplate = true
        return copy
    }
    #endif
}

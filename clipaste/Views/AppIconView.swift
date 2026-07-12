import AppKit
import SwiftUI

struct AppIconView: View {
    let appBundleID: String?
    var size: CGFloat = 16

    var body: some View {
        Group {
            if let icon = resolvedIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "macwindow")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }

    private var resolvedIcon: NSImage? {
        AppIconResolver.icon(for: appBundleID) ?? AppIconResolver.safariFallbackIcon
    }
}

private enum AppIconResolver {
    static let cache = NSCache<NSString, NSImage>()
    static let safariBundleIdentifier = "com.apple.Safari"

    static var safariFallbackIcon: NSImage? {
        icon(for: safariBundleIdentifier, allowFallback: false)
    }

    static func icon(for bundleIdentifier: String?, allowFallback: Bool = true) -> NSImage? {
        guard let bundleIdentifier = bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
              bundleIdentifier.isEmpty == false else {
            return allowFallback ? safariFallbackIcon : nil
        }

        if let cached = cache.object(forKey: bundleIdentifier as NSString) {
            return cached
        }

        guard let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return allowFallback ? safariFallbackIcon : nil
        }

        let icon = NSWorkspace.shared.icon(forFile: applicationURL.path)
        cache.setObject(icon, forKey: bundleIdentifier as NSString)
        return icon
    }
}

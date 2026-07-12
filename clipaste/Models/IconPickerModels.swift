import Combine
import Foundation
import SwiftUI

// MARK: - Model

enum IconType: String, Codable {
    case system  // SF Symbols — rendered with Image(systemName:)
    case custom  // Assets catalog — rendered with Image(_:) + .renderingMode(.template)
}

struct IconItem: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String         // e.g. "folder" or "python"
    let type: IconType       // determines rendering path
    let displayName: String  // friendly label used for search

    init(name: String, type: IconType = .system, displayName: String) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.displayName = displayName
    }
}

struct IconCategory: Identifiable {
    let id: UUID = UUID()
    let name: LocalizedStringKey
    let icons: [IconItem]
}

// MARK: - ViewModel

final class IconPickerViewModel: ObservableObject {
    // 搜索关键字（由 UI 绑定）
    @Published var searchQuery: String = ""

    // 所有可选图标（静态常量，避免重复构建）
    static let allIcons: [IconItem] = [
        // Common
        IconItem(name: "folder",                            type: .system, displayName: "Folder"),
        IconItem(name: "folder.fill",                      type: .system, displayName: "Folder Filled"),
        IconItem(name: "doc.text",                         type: .system, displayName: "Document"),
        IconItem(name: "terminal",                         type: .system, displayName: "Terminal"),
        IconItem(name: "chevron.left.forwardslash.chevron.right", type: .system, displayName: "Code"),
        IconItem(name: "paintpalette",                     type: .system, displayName: "Palette"),
        IconItem(name: "photo",                            type: .system, displayName: "Photo"),
        IconItem(name: "link",                             type: .system, displayName: "Link"),
        IconItem(name: "globe",                            type: .system, displayName: "Globe"),
        IconItem(name: "envelope",                         type: .system, displayName: "Email"),
        
        // Work
        IconItem(name: "cart",                             type: .system, displayName: "Cart"),
        IconItem(name: "creditcard",                       type: .system, displayName: "Credit Card"),
        IconItem(name: "briefcase",                        type: .system, displayName: "Briefcase"),
        IconItem(name: "lock.shield",                      type: .system, displayName: "Security"),
        IconItem(name: "key",                              type: .system, displayName: "Key"),
        IconItem(name: "star",                             type: .system, displayName: "Star"),
        IconItem(name: "heart",                            type: .system, displayName: "Heart"),
        IconItem(name: "bookmark",                         type: .system, displayName: "Bookmark"),
        IconItem(name: "flag",                             type: .system, displayName: "Flag"),
        IconItem(name: "bell",                             type: .system, displayName: "Bell"),
        
        // Storage
        IconItem(name: "tag",                              type: .system, displayName: "Tag"),
        IconItem(name: "tray",                             type: .system, displayName: "Tray"),
        IconItem(name: "archivebox",                       type: .system, displayName: "Archive"),
        IconItem(name: "shippingbox",                      type: .system, displayName: "Box"),
        IconItem(name: "books.vertical",                   type: .system, displayName: "Library"),
        IconItem(name: "externaldrive",                    type: .system, displayName: "Drive"),
        IconItem(name: "internaldrive",                    type: .system, displayName: "SSD"),
        IconItem(name: "icloud",                           type: .system, displayName: "iCloud"),
        IconItem(name: "server.rack",                      type: .system, displayName: "Server"),
        IconItem(name: "sdcard",                           type: .system, displayName: "SD Card"),
        
        // Languages
        IconItem(name: "python", type: .custom, displayName: "Python"),
        IconItem(name: "java", type: .custom, displayName: "Java"),
        IconItem(name: "swift", type: .custom, displayName: "Swift"),
        IconItem(name: "javascript", type: .custom, displayName: "JavaScript"),
        IconItem(name: "typescript", type: .custom, displayName: "TypeScript"),
        IconItem(name: "kotlin", type: .custom, displayName: "Kotlin"),
        IconItem(name: "rust", type: .custom, displayName: "Rust"),
        IconItem(name: "go", type: .custom, displayName: "Go"),
        IconItem(name: "cplusplus", type: .custom, displayName: "C++"),
        
        // Frameworks & Libs
        IconItem(name: "react", type: .custom, displayName: "React"),
        IconItem(name: "vuedotjs", type: .custom, displayName: "Vue.js"),
        IconItem(name: "angular", type: .custom, displayName: "Angular"),
        IconItem(name: "nodedotjs", type: .custom, displayName: "Node.js"),
        IconItem(name: "html5", type: .custom, displayName: "HTML5"),
        IconItem(name: "css", type: .custom, displayName: "CSS"),
        IconItem(name: "tailwindcss", type: .custom, displayName: "Tailwind CSS"),
        
        // Tools & Platforms
        IconItem(name: "git", type: .custom, displayName: "Git"),
        IconItem(name: "github", type: .custom, displayName: "GitHub"),
        IconItem(name: "docker", type: .custom, displayName: "Docker"),
        IconItem(name: "figma", type: .custom, displayName: "Figma"),
        IconItem(name: "apple", type: .custom, displayName: "Apple"),
        IconItem(name: "android", type: .custom, displayName: "Android"),
    ]

    // 方便实例访问
    var allIcons: [IconItem] { Self.allIcons }

    // 对外暴露的自定义图标名称集合，供其他模块（如 ClipboardGroupModel）判断是否为自定义图标
    static let customIconNames: Set<String> = {
        Set(allIcons.filter { $0.type == .custom }.map { $0.name })
    }()

    // MARK: Search

    /// Flat list of matching icons when a search query is active.
    var searchResults: [IconItem] {
        let q = searchQuery.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return allIcons
            .filter { $0.displayName.lowercased().contains(q) || $0.name.lowercased().contains(q) }
    }

    var isSearching: Bool { !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty }
    
    // MARK: Actions
    
    var displayedIcons: [IconItem] {
        isSearching ? searchResults : allIcons
    }
    
    func clearSearch() {
        searchQuery = ""
    }
}

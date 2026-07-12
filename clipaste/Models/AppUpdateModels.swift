import Foundation

enum AppUpdatePhase: Equatable {
    case idle
    case checking
    case updateAvailable
    case downloading
    case installing
    case upToDate
    case failed(String)
}

struct AppUpdateRelease: Equatable, Sendable {
    let version: String
    let buildVersion: String
    let title: String?
    let releaseNotesURL: URL?
    let publishedDate: Date?
}

struct AppUpdateServiceState: Equatable {
    var phase: AppUpdatePhase = .idle
    var availableUpdate: AppUpdateRelease?
    var canCheckForUpdates = false
    var automaticallyChecksForUpdates = true
    var automaticallyDownloadsUpdates = false
    var lastUpdateCheckDate: Date?
}

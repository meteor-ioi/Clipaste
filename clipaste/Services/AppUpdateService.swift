import Foundation
import Sparkle

@MainActor
protocol AppUpdateServicing: AnyObject {
    var currentState: AppUpdateServiceState { get }
    var onStateChange: ((AppUpdateServiceState) -> Void)? { get set }
    var automaticallyChecksForUpdates: Bool { get set }
    var automaticallyDownloadsUpdates: Bool { get set }

    func start()
    func probeForUpdates(force: Bool)
    func probeForUpdatesIfNeeded()
    func checkForUpdates()
}

@MainActor
final class SparkleAppUpdateService: NSObject, AppUpdateServicing {
    var onStateChange: ((AppUpdateServiceState) -> Void)?

    private(set) var currentState = AppUpdateServiceState()

    private let startupProbeInterval: TimeInterval = 6 * 60 * 60
    private var hasStarted = false

    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: self
    )

    private var updater: SPUUpdater {
        updaterController.updater
    }

    var automaticallyChecksForUpdates: Bool {
        get { updater.automaticallyChecksForUpdates }
        set {
            updater.automaticallyChecksForUpdates = newValue
            syncState()
        }
    }

    var automaticallyDownloadsUpdates: Bool {
        get { updater.automaticallyDownloadsUpdates }
        set {
            updater.automaticallyDownloadsUpdates = newValue
            syncState()
        }
    }

    override init() {
        super.init()
        syncState()
    }

    func start() {
        guard !hasStarted else {
            syncState()
            return
        }

        hasStarted = true
        updaterController.startUpdater()
        syncState()
    }

    func probeForUpdates(force: Bool) {
        start()

        guard updater.canCheckForUpdates else {
            syncState()
            return
        }

        guard force || shouldPerformStartupProbe else {
            syncState()
            return
        }

        mutateState {
            $0.phase = .checking
        }
        updater.checkForUpdateInformation()
    }

    func probeForUpdatesIfNeeded() {
        probeForUpdates(force: false)
    }

    func checkForUpdates() {
        start()

        guard updater.canCheckForUpdates else {
            syncState()
            return
        }

        mutateState {
            $0.phase = .checking
        }
        updater.checkForUpdates()
    }
}

private extension SparkleAppUpdateService {
    var shouldPerformStartupProbe: Bool {
        guard updater.automaticallyChecksForUpdates else { return false }
        guard let lastCheckDate = updater.lastUpdateCheckDate else { return true }
        return Date().timeIntervalSince(lastCheckDate) >= startupProbeInterval
    }

    func mutateState(_ updates: (inout AppUpdateServiceState) -> Void) {
        updates(&currentState)
        currentState.canCheckForUpdates = updater.canCheckForUpdates
        currentState.automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        currentState.automaticallyDownloadsUpdates = updater.automaticallyDownloadsUpdates
        currentState.lastUpdateCheckDate = updater.lastUpdateCheckDate
        onStateChange?(currentState)
    }

    func syncState() {
        mutateState { _ in }
    }

    func resolveRelease(from item: SUAppcastItem) -> AppUpdateRelease {
        AppUpdateRelease(
            version: AppMetadata.normalizedVersion(from: item.displayVersionString),
            buildVersion: item.versionString,
            title: item.title,
            releaseNotesURL: item.releaseNotesURL ?? item.fullReleaseNotesURL ?? item.infoURL,
            publishedDate: item.date
        )
    }

    func updateFailureMessage(for error: NSError) -> String? {
        guard error.domain == SUSparkleErrorDomain else {
            return error.localizedDescription
        }

        switch error.code {
        case 1001:
            return nil
        case 4007, 4008:
            return nil
        default:
            return error.localizedDescription
        }
    }
}

extension SparkleAppUpdateService: SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let release = resolveRelease(from: item)
        mutateState {
            $0.availableUpdate = release
            $0.phase = .updateAvailable
        }
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        mutateState {
            $0.availableUpdate = nil
            $0.phase = .upToDate
        }
    }

    func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        let release = resolveRelease(from: item)
        mutateState {
            $0.availableUpdate = release
            $0.phase = .updateAvailable
        }
    }

    func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        let release = resolveRelease(from: item)
        let message = updateFailureMessage(for: error as NSError) ?? (error as NSError).localizedDescription
        mutateState {
            $0.availableUpdate = release
            $0.phase = .failed(message)
        }
    }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        let release = resolveRelease(from: item)
        mutateState {
            $0.availableUpdate = release
            $0.phase = .installing
        }
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        guard let message = updateFailureMessage(for: error as NSError) else {
            syncState()
            return
        }

        mutateState {
            $0.phase = .failed(message)
        }
    }

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: (any Error)?
    ) {
        if let error,
           let message = updateFailureMessage(for: error as NSError) {
            mutateState {
                $0.phase = .failed(message)
            }
            return
        }

        syncState()
    }
}

extension SparkleAppUpdateService: SPUStandardUserDriverDelegate {}

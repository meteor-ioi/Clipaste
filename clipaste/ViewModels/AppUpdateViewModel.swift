import Foundation
import Observation

@MainActor
@Observable
final class AppUpdateViewModel {
    static let shared = AppUpdateViewModel()
    static let preview = AppUpdateViewModel(service: PreviewAppUpdateService())

    @ObservationIgnored
    private let service: AppUpdateServicing

    @ObservationIgnored
    private var isSynchronizingServiceState = false

    private(set) var currentVersion = AppMetadata.displayVersion
    private(set) var availableUpdate: AppUpdateRelease?
    private(set) var phase: AppUpdatePhase = .idle
    private(set) var canCheckForUpdates = false
    private(set) var lastUpdateCheckDate: Date?

    var automaticallyChecksForUpdates = true {
        didSet {
            guard !isSynchronizingServiceState,
                  automaticallyChecksForUpdates != oldValue else { return }

            service.automaticallyChecksForUpdates = automaticallyChecksForUpdates
            synchronize(with: service.currentState)
        }
    }

    var automaticallyDownloadsUpdates = false {
        didSet {
            guard !isSynchronizingServiceState,
                  automaticallyDownloadsUpdates != oldValue else { return }

            service.automaticallyDownloadsUpdates = automaticallyDownloadsUpdates
            synchronize(with: service.currentState)
        }
    }

    init() {
        self.service = SparkleAppUpdateService()
        self.synchronize(with: service.currentState)
        self.service.onStateChange = { [weak self] state in
            self?.synchronize(with: state)
        }
    }

    init(service: AppUpdateServicing) {
        self.service = service
        self.synchronize(with: service.currentState)
        self.service.onStateChange = { [weak self] state in
            self?.synchronize(with: state)
        }
    }

    var isCheckingForUpdates: Bool {
        phase == .checking
    }

    var isUpdateAvailable: Bool {
        availableUpdate != nil
    }

    var shouldShowUpdateBadge: Bool {
        isUpdateAvailable
    }

    func start() {
        currentVersion = AppMetadata.displayVersion
        service.start()
        synchronize(with: service.currentState)
    }

    func refreshAvailabilityIfNeeded() {
        service.probeForUpdatesIfNeeded()
    }

    func checkForUpdates() {
        service.probeForUpdates(force: true)
    }

    func installAvailableUpdate() {
        service.checkForUpdates()
    }
}

private extension AppUpdateViewModel {
    func synchronize(with state: AppUpdateServiceState) {
        isSynchronizingServiceState = true
        currentVersion = AppMetadata.displayVersion
        availableUpdate = state.availableUpdate
        phase = state.phase
        canCheckForUpdates = state.canCheckForUpdates
        automaticallyChecksForUpdates = state.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = state.automaticallyDownloadsUpdates
        lastUpdateCheckDate = state.lastUpdateCheckDate
        isSynchronizingServiceState = false
    }
}

@MainActor
private final class PreviewAppUpdateService: AppUpdateServicing {
    var onStateChange: ((AppUpdateServiceState) -> Void)?

    var currentState = AppUpdateServiceState(
        phase: .updateAvailable,
        availableUpdate: AppUpdateRelease(
            version: "1.1.0",
            buildVersion: "110",
            title: "Clipaste 1.1.0",
            releaseNotesURL: URL(string: "https://github.com/gangz1o/Clipaste/releases/latest"),
            publishedDate: Date()
        ),
        canCheckForUpdates: true,
        automaticallyChecksForUpdates: true,
        automaticallyDownloadsUpdates: false,
        lastUpdateCheckDate: Date()
    )

    var automaticallyChecksForUpdates: Bool {
        get { currentState.automaticallyChecksForUpdates }
        set {
            currentState.automaticallyChecksForUpdates = newValue
            onStateChange?(currentState)
        }
    }

    var automaticallyDownloadsUpdates: Bool {
        get { currentState.automaticallyDownloadsUpdates }
        set {
            currentState.automaticallyDownloadsUpdates = newValue
            onStateChange?(currentState)
        }
    }

    func start() {
        onStateChange?(currentState)
    }

    func probeForUpdates(force: Bool) {
        currentState.phase = .updateAvailable
        onStateChange?(currentState)
    }

    func probeForUpdatesIfNeeded() {
        onStateChange?(currentState)
    }

    func checkForUpdates() {
        currentState.phase = .installing
        onStateChange?(currentState)
    }
}

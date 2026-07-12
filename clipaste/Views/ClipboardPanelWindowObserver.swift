import AppKit
import SwiftUI

struct ClipboardPanelWindowObserver: NSViewRepresentable {
    let onWindowDidBecomeKey: () -> Void
    let onWindowDidResignKey: () -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onWindowDidBecomeKey = onWindowDidBecomeKey
        view.onWindowDidResignKey = onWindowDidResignKey
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {
        nsView.onWindowDidBecomeKey = onWindowDidBecomeKey
        nsView.onWindowDidResignKey = onWindowDidResignKey
    }

    final class TrackingView: NSView {
        var onWindowDidBecomeKey: (() -> Void)?
        var onWindowDidResignKey: (() -> Void)?

        private weak var observedWindow: NSWindow?
        nonisolated(unsafe) private var becomeKeyObserver: NSObjectProtocol?
        nonisolated(unsafe) private var resignKeyObserver: NSObjectProtocol?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            observeWindow(window)
        }

        deinit {
            if let becomeKeyObserver {
                NotificationCenter.default.removeObserver(becomeKeyObserver)
            }
            if let resignKeyObserver {
                NotificationCenter.default.removeObserver(resignKeyObserver)
            }
        }

        private func observeWindow(_ window: NSWindow?) {
            guard observedWindow !== window else { return }

            stopObservingWindow()
            observedWindow = window

            guard let window else { return }

            becomeKeyObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.onWindowDidBecomeKey?()
                }
            }

            resignKeyObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.onWindowDidResignKey?()
                }
            }

            if window.isKeyWindow {
                DispatchQueue.main.async { [weak self] in
                    self?.onWindowDidBecomeKey?()
                }
            }
        }

        private func stopObservingWindow() {
            if let becomeKeyObserver {
                NotificationCenter.default.removeObserver(becomeKeyObserver)
                self.becomeKeyObserver = nil
            }

            if let resignKeyObserver {
                NotificationCenter.default.removeObserver(resignKeyObserver)
                self.resignKeyObserver = nil
            }

            observedWindow = nil
        }
    }
}

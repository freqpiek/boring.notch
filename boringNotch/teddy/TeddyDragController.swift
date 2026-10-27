//
//  TeddyDragController.swift
//  boringNotch
//
//  Der Teddy lässt sich am Kopf aus der Notch ziehen: Solange die Maustaste gedrückt ist,
//  hängt er mit ganzem Körper an der Maus (Physik in teddy-drag.html). Beim Loslassen
//  fliegt er zurück in die Notch.
//
//  Aufbau: Ein durchsichtiges Fenster über dem ganzen Bildschirm zeigt die Webseite.
//  Das Fenster nimmt keine Mausklicks an, die Mausposition schickt dieser Controller
//  per Timer an die Seite.
//

import AppKit
import SwiftUI
import WebKit

@MainActor
final class TeddyDragController: NSObject, ObservableObject, WKScriptMessageHandler, WKNavigationDelegate {
    static let shared = TeddyDragController()

    /// true, solange der Teddy draußen ist. Der Kopf in der Notch blendet sich dann aus.
    @Published private(set) var isActive = false

    private var panel: NSPanel?
    private var web: WKWebView?
    private var pageLoaded = false
    private var timer: Timer?
    private var fallbackTask: Task<Void, Never>?
    private var screenFrame: NSRect = .zero

    private override init() {
        super.init()
    }

    // MARK: - Vorbereiten

    /// Lädt die Seite schon beim Start, damit das erste Ziehen sofort klappt.
    func preload() {
        guard panel == nil else { return }

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "teddy")

        let web = WKWebView(frame: .zero, configuration: config)
        web.setValue(false, forKey: "drawsBackground")
        web.navigationDelegate = self
        self.web = web

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.contentView = web
        self.panel = panel

        if let url = Bundle.main.url(forResource: "teddy-drag", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            NSLog("Teddy: teddy-drag.html nicht im Bundle gefunden")
        }
    }

    // MARK: - Ziehen

    /// Maustaste auf dem Kopf gedrückt. Gibt false zurück, wenn der Teddy noch nicht bereit ist.
    @discardableResult
    func begin() -> Bool {
        preload()
        guard pageLoaded, !isActive, let panel else { return false }

        let location = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(location, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        screenFrame = screen.frame

        panel.setFrame(screenFrame, display: false)
        panel.orderFrontRegardless()

        let p = webPoint(for: location)
        run("teddyDrag.begin(\(p.x), \(p.y))")
        isActive = true
        startTracking()
        return true
    }

    /// Maustaste losgelassen: Teddy fliegt zurück in die Notch.
    func end() {
        guard isActive else { return }
        timer?.invalidate()
        timer = nil
        pushMouse()
        run("teddyDrag.end()")

        // Notfall: Falls die Seite nicht "fertig" meldet, Fenster nach 2 Sekunden trotzdem schließen.
        fallbackTask?.cancel()
        fallbackTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.finish()
        }
    }

    private func finish() {
        fallbackTask?.cancel()
        fallbackTask = nil
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
        isActive = false
    }

    // MARK: - Maus an die Seite schicken

    private func startTracking() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pushMouse() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func pushMouse() {
        let p = webPoint(for: NSEvent.mouseLocation)
        run("teddyDrag.mouse(\(p.x), \(p.y))")
    }

    /// Bildschirmkoordinaten (Ursprung unten links) in Seitenkoordinaten (Ursprung oben links).
    private func webPoint(for location: NSPoint) -> CGPoint {
        CGPoint(x: location.x - screenFrame.minX, y: screenFrame.maxY - location.y)
    }

    private func run(_ script: String) {
        web?.evaluateJavaScript(script, completionHandler: nil)
    }

    // MARK: - WKScriptMessageHandler / WKNavigationDelegate

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let text = message.body as? String, text == "done" {
            finish()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pageLoaded = true
    }
}

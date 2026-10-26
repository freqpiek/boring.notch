//
//  TeddyWebView.swift
//  boringNotch
//
//  Zeigt den animierten Teddy (HTML/SVG) mit transparentem Hintergrund.
//

import SwiftUI
import WebKit

struct TeddyWebView: NSViewRepresentable {
    let state: TeddyState

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        web.setValue(false, forKey: "drawsBackground")
        web.navigationDelegate = context.coordinator
        context.coordinator.pending = state

        let url = Bundle.main.url(forResource: "teddy-view", withExtension: "html")
            ?? Bundle.main.url(forResource: "teddy-view", withExtension: "html", subdirectory: "teddy")
        if let url {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            NSLog("Teddy: teddy-view.html nicht im Bundle gefunden")
        }
        context.coordinator.web = web
        return web
    }

    func updateNSView(_ web: WKWebView, context: Context) {
        context.coordinator.apply(state)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var web: WKWebView?
        var pending: TeddyState = .idle
        private var loaded = false

        func apply(_ newState: TeddyState) {
            pending = newState
            if loaded { push() }
        }

        private func push() {
            web?.evaluateJavaScript("setTeddyState('\(pending.rawValue)')", completionHandler: nil)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loaded = true
            push()
        }
    }
}

/// Der Teddy-Kopf als einfache View, folgt automatisch dem Zustand des Assistenten.
struct TeddyFace: View {
    @ObservedObject private var assistant = TeddyAssistant.shared

    var body: some View {
        TeddyWebView(state: assistant.state)
            .allowsHitTesting(false)
    }
}

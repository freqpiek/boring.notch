//
//  TeddyAssistant.swift
//  boringNotch
//
//  Zustand und Ablauf des Teddy-Assistenten (Push-to-Talk).
//  Stufe 1: nur Demo-Ablauf. Mikrofon und Claude kommen in Stufe 2.
//

import Combine
import SwiftUI

enum TeddyState: String {
    case idle, listening, thinking, speaking, waving
}

@MainActor
final class TeddyAssistant: ObservableObject {
    static let shared = TeddyAssistant()

    @Published private(set) var state: TeddyState = .idle
    @Published private(set) var message: String = TeddyAssistant.defaultMessage

    /// Wird aufgerufen, wenn der Teddy fertig ist (die App klappt dann die Notch wieder zu).
    var onFinished: (@MainActor () -> Void)?

    static let defaultMessage = "Halte die Tastenkombination gedrückt und sprich mit mir."

    private var task: Task<Void, Never>?

    private init() {}

    func startListening() {
        task?.cancel()
        state = .listening
        message = "Ich höre zu …"
    }

    func stopListening() {
        guard state == .listening else { return }
        state = .thinking
        message = "Einen Moment …"
        task?.cancel()
        task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard !Task.isCancelled, let self else { return }
            self.state = .speaking
            self.message = "Hallo! Ich bin noch eine Demo. Mikrofon und Claude kommen im nächsten Schritt."
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            guard !Task.isCancelled else { return }
            self.finish()
        }
    }

    func wave() {
        task?.cancel()
        state = .waving
        message = "Hallo!"
        task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled, let self else { return }
            self.finish()
        }
    }

    private func finish() {
        state = .idle
        message = TeddyAssistant.defaultMessage
        onFinished?()
    }
}

//
//  TeddyAssistantView.swift
//  boringNotch
//
//  Der Teddy-Tab im geöffneten Notch: großer Teddy links, Text rechts.
//

import SwiftUI

struct TeddyAssistantView: View {
    @ObservedObject private var assistant = TeddyAssistant.shared

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            TeddyFace()
                .frame(width: 120, height: 100)

            VStack(alignment: .leading, spacing: 6) {
                Text("Teddy")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(assistant.message)
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture { assistant.wave() }
    }
}

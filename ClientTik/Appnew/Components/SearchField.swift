import SwiftUI
import UIKit

struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField(placeholder, text: $text).disableAutocorrection(true)
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
            }
        }
        .padding(10)
        .background(Theme.card)
        .cornerRadius(12)
    }
}

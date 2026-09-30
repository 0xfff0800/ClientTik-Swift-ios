import SwiftUI
import UIKit

struct StatTile: View {
    let value: String, label: String, icon: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.footnote).foregroundColor(Theme.accent)
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.card)
        .cornerRadius(14)
    }
}

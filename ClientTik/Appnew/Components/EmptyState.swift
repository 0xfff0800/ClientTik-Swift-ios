import SwiftUI
import UIKit

struct EmptyState: View {
    let icon: String, title: String, message: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 44)).foregroundColor(.secondary.opacity(0.6))
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }
}

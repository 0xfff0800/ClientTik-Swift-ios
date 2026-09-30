import SwiftUI
import UIKit

enum Theme {
    static let accent = Color(red: 0.99, green: 0.17, blue: 0.33)
    static let gradient = LinearGradient(colors: [Color(red: 0.99, green: 0.17, blue: 0.33), Color(red: 0.55, green: 0.2, blue: 0.95)],
                                         startPoint: .leading, endPoint: .trailing)
    static let card = Color(UIColor.secondarySystemBackground)
    static let bg = Color(UIColor.systemBackground)
}

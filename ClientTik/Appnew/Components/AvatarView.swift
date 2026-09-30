import SwiftUI
import UIKit

struct AvatarView: View {
    let url: URL?
    let name: String
    let size: CGFloat
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Circle().fill(color)
                Text(String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased())
                    .font(.system(size: size * 0.42, weight: .bold)).foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
        .onAppear { load() }
    }

    private var color: Color {
        let hue = Double(abs(name.hashValue) % 360) / 360
        return Color(hue: hue, saturation: 0.55, brightness: 0.75)
    }

    private func load() {
        guard image == nil, let url = url else { return }
        ImageLoader.shared.load(url) { img in self.image = img }
    }
}

final class ImageLoader {
    static let shared = ImageLoader()
    private let cache = NSCache<NSURL, UIImage>()

    func load(_ url: URL, completion: @escaping (UIImage?) -> Void) {
        if let img = cache.object(forKey: url as NSURL) { completion(img); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let img = data.flatMap(UIImage.init(data:))
            if let img = img { self.cache.setObject(img, forKey: url as NSURL) }
            DispatchQueue.main.async { completion(img) }
        }.resume()
    }
}

import SwiftUI
import UIKit

@MainActor
final class SavedStore: ObservableObject {
    @Published private(set) var items: [Comment] = []
    private var ids = Set<String>()

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("saved_comments.json")
    }()

    init() {
        if let data = try? Data(contentsOf: fileURL),
           let list = try? JSONDecoder().decode([Comment].self, from: data) {
            items = list
            ids = Set(list.map { $0.cid })
        }
    }

    var storageBytes: Int {
        (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int) ?? 0
    }

    func contains(_ cid: String) -> Bool { ids.contains(cid) }

    func toggle(_ comment: Comment, videoID: String) {
        if ids.contains(comment.cid) { remove(comment.cid) } else { add([comment], videoID: videoID) }
    }

    func add(_ comments: [Comment], videoID: String) {
        var new = items
        for var c in comments where !ids.contains(c.cid) {
            c.videoID = videoID
            c.savedAt = Date()
            new.insert(c, at: 0)
            ids.insert(c.cid)
        }
        items = new
        persist()
    }

    func remove(_ cid: String) {
        items.removeAll { $0.cid == cid }
        ids.remove(cid)
        persist()
    }

    func removeAll() {
        items = []; ids = []
        persist()
    }

    private func persist() {
        let snapshot = items
        let url = fileURL
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(snapshot) { try? data.write(to: url, options: .atomic) }
        }
    }
}

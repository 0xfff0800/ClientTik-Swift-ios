import SwiftUI
import UIKit

struct CommentCard: View {
    let comment: Comment
    let videoID: String
    @EnvironmentObject var store: SavedStore
    @State private var copied = false

    var body: some View {
        let saved = store.contains(comment.cid)
        HStack(alignment: .top, spacing: 12) {
            AvatarView(url: comment.avatarURL, name: comment.displayName, size: 44)
                .onTapGesture { openProfile() }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(comment.displayName).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(verbatim: "\u{200E}@\(comment.username)").font(.caption).foregroundColor(.secondary).lineLimit(1)
                    Spacer(minLength: 0)
                }
                Text(comment.text).font(.body).fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    if let d = comment.date {
                        Text(RelativeFormatter.string(from: d)).font(.caption).foregroundColor(.secondary)
                    }
                    Label(comment.likes.compact, systemImage: "heart").font(.caption).foregroundColor(.secondary)
                    if comment.replies > 0 {
                        Label(comment.replies.compact, systemImage: "arrowshape.turn.up.left").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = comment.text
                        Haptics.success()
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.footnote)
                            .foregroundColor(copied ? .green : .secondary)
                    }.buttonStyle(PlainButtonStyle())
                    Button {
                        store.toggle(comment, videoID: videoID)
                        Haptics.tap()
                    } label: {
                        Image(systemName: saved ? "bookmark.fill" : "bookmark").font(.body)
                            .foregroundColor(saved ? Theme.accent : .secondary)
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(Theme.card)
        .cornerRadius(16)
        .contextMenu {
            Button { UIPasteboard.general.string = comment.text } label: { Label("نسخ التعليق", systemImage: "doc.on.doc") }
            Button { UIPasteboard.general.string = comment.username } label: { Label("نسخ اسم المستخدم", systemImage: "at") }
            Button { openProfile() } label: { Label("فتح الحساب", systemImage: "person.crop.circle") }
            Button { store.toggle(comment, videoID: videoID) } label: {
                Label(saved ? "إزالة من المحفوظات" : "حفظ", systemImage: saved ? "bookmark.slash" : "bookmark")
            }
        }
    }

    private func openProfile() {
        if let url = URL(string: "https://www.tiktok.com/@\(comment.username)") { UIApplication.shared.open(url) }
    }
}

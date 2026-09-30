import SwiftUI
import UIKit

struct FetchScreen: View {
    @EnvironmentObject var model: FetchModel
    @EnvironmentObject var store: SavedStore
    @State private var search = ""
    @State private var sort: SortOrder = .original
    @State private var shareItems: [Any]?
    @State private var showAbout = false

    private var visible: [Comment] {
        var list = model.comments
        if !search.isEmpty {
            list = list.filter {
                $0.text.localizedCaseInsensitiveContains(search) ||
                $0.username.localizedCaseInsensitiveContains(search) ||
                $0.nickname.localizedCaseInsensitiveContains(search)
            }
        }
        switch sort {
        case .original: return list
        case .newest: return list.sorted { $0.createTime > $1.createTime }
        case .oldest: return list.sorted { $0.createTime < $1.createTime }
        case .likes: return list.sorted { $0.likes > $1.likes }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12, pinnedViews: []) {
                    inputCard

                    if !model.status.isEmpty { statusView }

                    if !model.comments.isEmpty {
                        statsRow
                        SearchField(text: $search, placeholder: "ابحث في الاسم أو النص")
                        sortBar

                        if visible.isEmpty {
                            EmptyState(icon: "magnifyingglass", title: "لا نتائج", message: "جرّب كلمة بحث مختلفة")
                                .padding(.top, 30)
                        }
                        ForEach(visible) { comment in
                            CommentCard(comment: comment, videoID: model.videoID ?? "")
                        }
                    } else if !model.isLoading && model.status.isEmpty {
                        EmptyState(icon: "text.bubble",
                                   title: "ابدأ بلصق رابط الفيديو",
                                   message: "الصق رابط تيك توك (حتى المختصر) وسيتم استخراج رقم الفيديو وجلب كل التعليقات تلقائياً")
                            .padding(.top, 50)
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationBarTitle("تعليقات تيك توك", displayMode: .large)
            .navigationBarItems(trailing: exportMenu)
            .sheet(isPresented: Binding(get: { shareItems != nil }, set: { if !$0 { shareItems = nil } })) {
                ShareSheet(items: shareItems ?? [])
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAbout) {
            AboutScreen().environmentObject(store).environment(\.layoutDirection, .rightToLeft)
        }
    }

    // MARK: pieces

    private var inputCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "link").foregroundColor(.secondary)
                TextField("رابط تيك توك أو رقم الفيديو", text: $model.input, onCommit: { if canStart { model.start() } })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .environment(\.layoutDirection, .leftToRight)
                    .multilineTextAlignment(.leading)
                if !model.input.isEmpty {
                    Button { model.input = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                } else {
                    Button {
                        if let s = UIPasteboard.general.string { model.input = s; Haptics.tap() }
                    } label: {
                        Text("لصق").font(.subheadline.weight(.semibold)).foregroundColor(Theme.accent)
                    }
                }
            }
            .padding(12)
            .background(Theme.bg)
            .cornerRadius(12)

            Button(action: { model.isLoading ? model.cancel() : model.start() }) {
                HStack(spacing: 8) {
                    Image(systemName: model.isLoading ? "stop.fill" : "arrow.down.circle.fill")
                    Text(model.isLoading ? "إيقاف" : "جلب التعليقات").fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundColor(.white)
                .background(model.isLoading ? AnyView(Color.gray) : AnyView(Theme.gradient))
                .cornerRadius(14)
                .opacity(canStart || model.isLoading ? 1 : 0.5)
            }
            .disabled(!canStart && !model.isLoading)
        }
        .padding(14)
        .background(Theme.card)
        .cornerRadius(18)
    }

    private var canStart: Bool { !model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var statusView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if model.isLoading { ProgressView() }
                else { Image(systemName: model.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(model.isError ? .orange : .green) }
                Text(model.status).font(.subheadline)
                Spacer()
            }
            if model.isLoading && model.total > 0 {
                ProgressBar(value: Double(model.comments.count) / Double(model.total))
            }
            if let id = model.videoID {
                HStack {
                    Text("رقم الفيديو").font(.caption).foregroundColor(.secondary)
                    Text(verbatim: id).font(.caption.weight(.medium)).environment(\.layoutDirection, .leftToRight)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = id; Haptics.success()
                    } label: { Image(systemName: "doc.on.doc").font(.caption) }
                }
            }
        }
        .padding(12)
        .background(Theme.card)
        .cornerRadius(14)
    }

    private var statsRow: some View {
        let users = Set(model.comments.map { $0.username }).count
        let likes = model.comments.reduce(0) { $0 + $1.likes }
        return HStack(spacing: 8) {
            StatTile(value: model.comments.count.compact, label: "تعليق", icon: "text.bubble.fill")
            StatTile(value: users.compact, label: "مستخدم", icon: "person.2.fill")
            StatTile(value: likes.compact, label: "إعجاب", icon: "heart.fill")
        }
    }

    private var sortBar: some View {
        HStack {
            Text("\(visible.count) نتيجة").font(.footnote).foregroundColor(.secondary)
            Spacer()
            Menu {
                Picker("الترتيب", selection: $sort) {
                    ForEach(SortOrder.allCases) { Text($0.rawValue).tag($0) }
                }
            } label: {
                Label(sort.rawValue, systemImage: "arrow.up.arrow.down").font(.footnote.weight(.medium))
            }
        }
    }

    private var exportMenu: some View {
        Menu {
            Button { store.add(visible, videoID: model.videoID ?? ""); Haptics.success() } label: {
                Label("حفظ كل النتائج", systemImage: "bookmark")
            }
            .disabled(model.comments.isEmpty)
            Button { shareItems = [ExportService.csvFile(for: visible, name: "comments-\(model.videoID ?? "video")")].compactMap { $0 } } label: {
                Label("تصدير CSV", systemImage: "square.and.arrow.up")
            }
            .disabled(model.comments.isEmpty)
            Button { model.clear() } label: {
                Label("مسح النتائج", systemImage: "trash")
            }
            .disabled(model.comments.isEmpty)
            AboutMenuItems(show: $showAbout)
        } label: {
            Image(systemName: "ellipsis.circle").font(.title3)
        }
    }
}

import SwiftUI
import Alamofire

struct ContentView: View {
    @State private var videoid: String = ""
    @State private var cursor = 0
    @State private var comments: [Comment] = []
    @State private var searchText: String = ""
    @State private var filteredComments: [Comment] = []
    @State private var showAlert = false
    @State private var alertMessage = ""


    var body: some View {
        NavigationView {
            VStack {
                TextField("TikTok ID Video :", text: $videoid)
                    .padding()
                
                Button(action: {
    fetchComments()
                }) {
                    Text("Get Comments")
                        .frame(width: 200, height: 50)
                        .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.5))
                        .shadow(color: .blue, radius: 10, x: 0, y: 0)
                }
                
                TextField("Search", text: $searchText)
                    .padding()
                
                List(filteredComments, id: \.id) { comment in
                    VStack(alignment: .leading) {
                        Text("Username: \(comment.user.unique_id)")
                        Text(comment.text)
                    }
                }
                
                Spacer()
                
                VStack {
                    Link(" Twitter/x: @0xFaLaH  ", destination: URL(string: "https://twitter.com/0xFaLaH")!)
                        .font(.footnote)
                        .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.5))
                        .shadow(color: .blue, radius: 10, x: 0, y: 0)
                    
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            let lastCommentIndex = filteredComments.count - 1
            if lastCommentIndex >= 0 && lastCommentIndex == comments.count - 1 {
                fetchComments()
            }
        }
        .onChange(of: searchText) { _ in
            filterComments()
        }
    }
    

    

    func fetchComments() {
        var temporaryVideoid = videoid 
        self.videoid = temporaryVideoid 

    
    let headers: HTTPHeaders = [
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36",
        "referer": "https://www.tiktok.com/@x/video/\(videoid)"
    ]
    
    let urlString = "https://www.tiktok.com/api/comment/list/?aid=1988&aweme_id=\(videoid)&count=9999999&cursor=\(cursor)"

    guard let url = URL(string: urlString) else {
        return
    }
    
    AF.request(url, headers: headers).responseDecodable(of: CommentListResponse.self) { response in
        switch response.result {
        case .success(let commentListResponse):
            DispatchQueue.main.async {
                self.comments = commentListResponse.comments
                self.cursor += commentListResponse.comments.count 
                self.filterComments() 
                self.videoid = temporaryVideoid 
            }
        case .failure(let error):
                self.showAlert = true
                self.alertMessage = "حدث خطأ"

        }
    }
}
    
    func filterComments() {
        if searchText.isEmpty {
            filteredComments = comments
        } else {
            filteredComments = comments.filter { comment in
            return comment.user.unique_id.localizedCaseInsensitiveContains(searchText) || comment.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct CommentListResponse: Codable {
    let comments: [Comment]
}

struct Comment: Codable, Identifiable, Hashable {
    let id = UUID()
    let text: String
    let user: User
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id
    }
}

struct User: Codable {
    let unique_id: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import SwiftUI
import UIKit

struct APICommentList: Decodable {
    let comments: [APIComment]?
    let cursor: Int?
    let has_more: Int?
    let total: Int?
}

struct APIComment: Decodable {
    struct APIUser: Decodable {
        struct Avatar: Decodable { let url_list: [String]? }
        let unique_id: String?
        let nickname: String?
        let avatar_thumb: Avatar?
        let avatar_medium: Avatar?
    }
    let cid: String
    let text: String?
    let create_time: Int?
    let digg_count: Int?
    let reply_comment_total: Int?
    let user: APIUser?
}

/// نموذج مسطّح يُستخدم في الواجهة ويُحفظ على الجهاز.

struct Comment: Codable, Identifiable, Hashable {
    let cid: String
    let text: String
    let username: String
    let nickname: String
    let avatar: String?
    let createTime: Int
    let likes: Int
    let replies: Int
    var videoID: String = ""
    var savedAt: Date? = nil

    var id: String { cid }
    var displayName: String { nickname.isEmpty ? username : nickname }
    var avatarURL: URL? { avatar.flatMap(URL.init(string:)) }
    var date: Date? { createTime > 0 ? Date(timeIntervalSince1970: TimeInterval(createTime)) : nil }

    init(api c: APIComment, videoID: String) {
        cid = c.cid
        text = c.text ?? ""
        username = c.user?.unique_id ?? ""
        nickname = c.user?.nickname ?? ""
        avatar = c.user?.avatar_medium?.url_list?.first ?? c.user?.avatar_thumb?.url_list?.first
        createTime = c.create_time ?? 0
        likes = c.digg_count ?? 0
        replies = c.reply_comment_total ?? 0
        self.videoID = videoID
    }
}

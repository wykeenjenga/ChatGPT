//
//  APChatModel.swift
//  ChatGPT
//
//  Created by Wykee on 29/01/2023.
//

import Foundation
import UIKit
import MessageKit

struct MessageUser: SenderType {
    var senderId: String
    var displayName: String
}

struct Message: Codable {
    var id: String = ""
    var username:String = ""
    var message:String = ""
    var isUser: Bool = false
    var created: Date
    
    init(id: String, username: String, message:String, isUser: Bool, created: Date) {
        self.username = username
        self.isUser = isUser
        self.message = message
        self.id = id
        self.created = created
    }
}

extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
     return lhs.id == rhs.id &&
     lhs.message == rhs.message &&
     lhs.isUser == rhs.isUser
    }
}

extension Message: MessageType {
    var sender: SenderType {
        return Sender(senderId: id, displayName: username)
    }
    var messageId: String {
        return id
    }
    var sentDate: Date {
        return created
    }
    var kind: MessageKind {
        return .text(message)
    }
}

extension UIScrollView {
    var isAtBottom: Bool {
        return contentOffset.y >= verticalOffsetForBottom
    }
    var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }
}

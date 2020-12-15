//
//  Comment.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/25/20.
//

import Foundation

class Comment {
    var text: String
    var netId: String
    var userId: String
    var commentId: String
    var placeId: String
    
    init?(text: String, netId: String, userId: String, commentId: String, placeId: String) {
        if (text.isEmpty || netId.isEmpty || userId.isEmpty || commentId.isEmpty || placeId.isEmpty){
            return nil;
        }
        self.text = text
        self.netId = netId
        self.userId = userId
        self.commentId = commentId
        self.placeId = placeId
    }
}

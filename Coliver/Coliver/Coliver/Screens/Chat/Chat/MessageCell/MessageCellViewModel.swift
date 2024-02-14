//
//  MessageViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.12.2023.
//

import Foundation

final class MessageCellViewModel: ObservableObject {
    var id: Int
    var userName: String
    var messageText: String
    var date: String = ""
    
    init(model: MessageModel) {
        self.id = model.id
        self.userName = model.userName
        self.messageText = model.messageText
        
        let diffrence = model.timestamp.timeIntervalSince(Date())
        if diffrence <= 60 * 60 * 24 {
            self.date = model.timestamp.formatted(date: .omitted, time: .shortened)
        } else {
            self.date = model.timestamp.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

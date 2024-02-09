//
//  ChatModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 27.08.2023.
//

import Foundation

struct ChatModel: Codable {
	var id: Int
	var userName: String
	var lastMessage: String?
	var timestamp: Date?
}

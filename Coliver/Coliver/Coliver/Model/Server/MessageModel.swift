//
//  MessageModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 27.08.2023.
//

import Foundation

struct MessageModel: Codable {
	var id: Int
	var userName: String
	var messageText: String
	var timestamp: Date
}

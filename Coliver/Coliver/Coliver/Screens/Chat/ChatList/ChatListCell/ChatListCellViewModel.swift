//
//  ChatListCellViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 27.08.2023.
//

import Foundation

final class ChatListCellViewModel: ObservableObject {
	
	// MARK: - Properties
	
	let id: Int
	@Published var name: String
	@Published var date: String = ""
	@Published var text: String
	
	// MARK: - Initialization
	
	init(model: ChatModel) {
		id = model.id
		name = model.userName
		text = model.lastMessage ?? "Пусто"
		
        guard let timestamp = model.timestamp else { return }
		let diffrence = timestamp.timeIntervalSince(Date())
		if diffrence <= 60 * 60 * 24 {
			date = timestamp.formatted(date: .omitted, time: .shortened)
		} else {
			date = timestamp.formatted(date: .abbreviated, time: .shortened)
		}
	}
}

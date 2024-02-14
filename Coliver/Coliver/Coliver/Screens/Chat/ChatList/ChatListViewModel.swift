//
//  ChatListViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 27.08.2023.
//

import Foundation
import Combine

final class ChatListViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum State: StateProtocol {
		case loading
		case loaded
		case empty
		case error
	}
	
	enum Event: EventProtocol {
		case loading
		case loaded
		case empty
		case error
	}
	
	// MARK: - Porperties
	
	@Published var cellViewModels: [ChatListCellViewModel] = []
	
	private(set) var stateMachine = StateMachine<State, Event>(state: .loading)
	private var state: State = .loading
	
	private let chatService: ChatServiceProtocol
	
	// MARK: - Initialization
	
	init(chatService: ChatServiceProtocol = ChatService()) {
		self.chatService = chatService
	}
    
    func onAppear() {
        Task { @MainActor in
            do {
                let chats = try await chatService.getChats()
                cellViewModels = chats.map { ChatListCellViewModel(model: $0) }
            } catch {
                print(error)
            }
        }
    }
}

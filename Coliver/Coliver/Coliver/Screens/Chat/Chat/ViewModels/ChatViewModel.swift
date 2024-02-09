//
//  ChatViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.12.2023.
//

import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    
    enum PaginationState {
        case isLoading
        case idle
        case finished
        case error
    }
    
    @Published var messages: [MessageCellViewModel] = []
    @Published var paginationState: PaginationState = .idle
    @Published var text: String = ""
    
    private let chatService: ChatServiceProtocol
    private let messageService: MessageServiceProtocol
    private let id: Int
    private var page: Int = 0
    
    init(
        id: Int,
        chatService: ChatServiceProtocol = ChatService(),
        messageService: MessageServiceProtocol = MessageService()
    ) {
        self.id = id
        self.chatService = chatService
        self.messageService = messageService
    }
    
    func onAppear() {
        loadMessages()
        messageService.connect()
        
        Task { @MainActor in
            for await message in messageService.messageStream {
                messages.insert(MessageCellViewModel(model: message), at: 0)
            }
        }
    }
    
    func onLastMessageAppear() {
        loadMessages()
    }
    
    func sendButtonTapped() {
        guard !text.isEmpty else { return }
        messageService.sendMessage(chatId: id, text: text)
        text = ""
    }
    
    private func loadMessages() {
        guard paginationState != .finished else { return }
        paginationState = .isLoading
        
        Task { @MainActor in
            do {
                let messageModels = try await chatService.getMessages(chatId: id, page: page)
                guard !messageModels.isEmpty else {
                    paginationState = .finished
                    return
                }
                messages += messageModels.map { MessageCellViewModel(model: $0) }
                paginationState = .idle
            } catch {
                paginationState = .finished
            }
        }
    }
}

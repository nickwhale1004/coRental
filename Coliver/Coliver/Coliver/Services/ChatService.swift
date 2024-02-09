//
//  ChatService.swift
//  Coliver
//
//  Created by Никита Шляхов on 27.08.2023.
//

import Foundation
import Combine

protocol ChatServiceProtocol {
	func getChats() async throws -> [ChatModel]
	func getMessages(chatId: Int, page: Int) async throws -> [MessageModel]
	func createChat(userId: Int) async throws
}

final class ChatService: ChatServiceProtocol {
	
	// MARK: - Types
	
	struct ResponseChats: Codable {
		var chats: [ChatModel]
	}
	
	struct ResponseMessages: Codable {
		var messages: [MessageModel]
	}
	
	struct RequestMessages: Codable {
		var token: String
		var chatId: Int
		var page: Int
	}
	
	struct RequestSendMessage: Codable {
		var token: String
		var chatId: Int
		var text: String
	}
	
	struct RequestCreateChat: Codable {
		var token: String
		var userId: Int
	}
	
	// MARK: - Properties
	
	private let url = "http://127.0.0.1:5000/"
	private let networkService: NetworkServiceProtocol
	private let authManager: AuthManagerProtocol
	
	// MARK: - Initialization
	
	init(
        networkService: NetworkServiceProtocol = NetworkService(),
		authManager: AuthManagerProtocol = AuthManager.shared
	) {
		self.networkService = networkService
		self.authManager = authManager
	}
	
	// MARK: - Methods
	
    func getChats() async throws -> [ChatModel] {
		guard
			let token = authManager.token
		else {
            throw AuthError.userAnauthorized
		}
		let body = ["token": token]
		
        let response: ResponseChats = try await networkService.request(url: url + "getChats", body: body)
        return response.chats
	}
	
    func getMessages(chatId: Int, page: Int) async throws -> [MessageModel] {
        guard
            let token = authManager.token
        else {
            throw AuthError.userAnauthorized
        }
        let body = RequestMessages(token: token, chatId: chatId, page: page)
        
        let response: ResponseMessages = try await networkService.request(url: url + "getMessages", body: body)
        return response.messages
	}
	
    func createChat(userId: Int) async throws {
        guard
            let token = authManager.token
        else {
            throw AuthError.userAnauthorized
        }
        
        let body = RequestCreateChat(token: token, userId: userId)
        
        try await networkService.request(url: url + "createChat", body: body)
	}
}

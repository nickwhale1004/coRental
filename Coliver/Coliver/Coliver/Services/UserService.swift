//
//  ApiService+User.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import Foundation
import Combine

protocol UserServiceProtocol {
	func getUser() async throws -> UserModel
	func updateUser(_ user: UserModel) async throws
	func search() async throws -> [SearchUserModel]
    func like(userId: Int) async throws
    func unlike(userId: Int) async throws
}

final class UserService: UserServiceProtocol {
	
	// MARK: - Types
	
	struct ResponseSearchModel: Decodable {
		let users: [SearchUserModel]
	}
	
	struct UpdateUserRequest: Codable {
		var token: String
		var user: UserModel
	}
    
    struct LikeUnlikeRequest: Codable {
        var token: String
        var targetUserId: Int
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
	
    func getUser() async throws -> UserModel {
		guard
			let token = authManager.token
		else {
            throw AuthError.userAnauthorized
		}
		let body = ["token": token]
        let response: UserModel = try await networkService.request(url: url + "getUser", body: body)
		return response
	}
	
    func updateUser(_ user: UserModel) async throws {
        guard
            let token = authManager.token
        else {
            throw AuthError.userAnauthorized
        }
        let body = UpdateUserRequest(token: token, user: user)
        try await networkService.request(url: url + "updateUser", body: body)
	}
	
    func search() async throws -> [SearchUserModel] {
        guard
            let token = authManager.token
        else {
            throw AuthError.userAnauthorized
        }
        let body = ["token": token]
        let response: ResponseSearchModel = try await networkService.request(url: url + "searchUsers", body: body)
        return response.users
	}
    
    func like(userId: Int) async throws {
        guard
            let token = authManager.token
        else {
            throw AuthError.userAnauthorized
        }
        let body = LikeUnlikeRequest(token: token, targetUserId: userId)
        try await networkService.request(url: url + "like", body: body)
    }
    
    func unlike(userId: Int) async throws {
        guard
            let token = authManager.token
        else {
            throw AuthError.userAnauthorized
        }
        let body = LikeUnlikeRequest(token: token, targetUserId: userId)
        try await networkService.request(url: url + "unlike", body: body)
    }
}

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
	func search() async throws -> [UserModel]
}

final class UserService: UserServiceProtocol {
	
	// MARK: - Types
	
	struct ResponseSearchModel: Codable {
		let users: [UserModel]
	}
	
	struct UpdateUserBody: Codable {
		var token: String
		var user: UserModel
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
        let body = UpdateUserBody(token: token, user: user)
        try await networkService.request(url: url + "updateUser", body: body)
	}
	
    func search() async throws -> [UserModel] {
        guard
            let token = authManager.token
        else {
            throw AuthError.userAnauthorized
        }
        let body = ["token": token]
        let response: ResponseSearchModel = try await networkService.request(url: url + "searchUsers", body: body)
        return response.users
	}
}

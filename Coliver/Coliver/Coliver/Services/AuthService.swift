//
//  ApiService+Auth.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import Foundation
import Combine

protocol AuthServiceProtocol {
	func register(user: UserModel, login: String, password: String) async throws -> String
	func login(login: String, password: String) async throws -> String
	func checkToken(_ token: String) async throws -> Bool
}

enum AuthError: Error {
    case userAnauthorized
}

final class AuthService: AuthServiceProtocol {
	
	// MARK: - Types
	
	struct RegisterRequest: Codable {
		var login: String
		var password: String
		var user: UserModel
	}
    
    struct RegisterResponse: Codable {
        var token: String
    }
	
	// MARK: - Properties
	
	private let url = "http://127.0.0.1:5000/"
	private let networkService: NetworkServiceProtocol
	
	// MARK: - Initialization
	
    init(networkService: NetworkServiceProtocol = NetworkService()) {
		self.networkService = networkService
	}
	
	// MARK: - Methods
	
    func register(user: UserModel, login: String, password: String) async throws -> String {
		let body = RegisterRequest(login: login, password: password, user: user)
        
        let response: RegisterResponse = try await networkService.request(url: url + "register", body: body)
        return response.token
	}
	
    func login(login: String, password: String) async throws -> String {
        let body = ["login": login, "password": password]
		
        let response: RegisterResponse = try await networkService.request(url: url + "login", body: body)
        return response.token
	}
	
    func checkToken(_ token: String) async throws -> Bool {
        let body = ["token": token]
        
        try await networkService.request(url: url + "verify_token", body: body)
        return true
	}
}

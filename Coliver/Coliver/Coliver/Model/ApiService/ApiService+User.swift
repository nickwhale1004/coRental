//
//  ApiService+User.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import Foundation
import Combine

extension ApiService {
	
	// MARK: - Types
	
	struct ResponseSearchModel: Codable {
		let users: [UserModel]
	}
	
	struct UpdateUserBody: Codable {
		var token: String
		var user: UserModel
	}
	
	// MARK: - Methods
	
	func getUser() -> AnyPublisher<UserModel, Error> {
		guard
			let url = URL(string: apiURL + "getUser"),
			let token = AuthManager.shared.token
		else {
			return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
		}
		
		let body = ["token": token]
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try? JSONEncoder().encode(body)
		
		return URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response -> UserModel in
				guard
					let httpResponse = response as? HTTPURLResponse,
					httpResponse.statusCode == 200
				else {
					throw URLError(.badServerResponse)
				}
				
				let decoder = JSONDecoder()
				if let userModel = try? decoder.decode(UserModel.self, from: data) {
					return userModel
				} else {
					throw URLError(.badServerResponse)
				}
			}
			.eraseToAnyPublisher()
	}
	
	func updateUser(_ user: UserModel) -> AnyPublisher<Void, Error> {
		guard
			let token = AuthManager.shared.token,
			let url = URL(string: apiURL + "updateUser")
		else {
			return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
		}
		
		let body = UpdateUserBody(token: token, user: user)
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try? JSONEncoder().encode(body)
		
		return URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response -> Void in
				guard
					let httpResponse = response as? HTTPURLResponse,
					httpResponse.statusCode == 200
				else {
					throw URLError(.badServerResponse)
				}
				return
			}
			.eraseToAnyPublisher()
	}
	
	func search() -> AnyPublisher<[UserModel], Error> {
		guard
			let token = AuthManager.shared.token,
			let url = URL(string: apiURL + "searchUsers")
		else {
			return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try? JSONSerialization.data(withJSONObject: ["token": token], options: [])
		
		return URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response -> [UserModel] in
				guard
					let httpResponse = response as? HTTPURLResponse,
					httpResponse.statusCode == 200
				else {
					throw URLError(.badServerResponse)
				}
				let decoder = JSONDecoder()
				let responseModel = try decoder.decode(ResponseSearchModel.self, from: data)
				return responseModel.users
			}
			.eraseToAnyPublisher()
	}
}

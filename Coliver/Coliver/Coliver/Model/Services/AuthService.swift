//
//  ApiService+Auth.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import Foundation
import Combine

protocol AuthServiceProtocol {
	func register(user: UserModel, login: String, password: String) -> AnyPublisher<String, Error>
	func login(login: String, password: String) -> AnyPublisher<String, Error>
	func checkToken(_ token: String) -> AnyPublisher<Bool, Error>
}

final class AuthService: AuthServiceProtocol {
	
	// MARK: - Types
	
	struct RegisterBody: Codable {
		var login: String
		var password: String
		var user: UserModel
	}
	
	// MARK: - Properties
	
	let url = "http://127.0.0.1:5000/"
	
	// MARK: - Methods
	
	func register(user: UserModel, login: String, password: String) -> AnyPublisher<String, Error> {
		guard
			let url = URL(string: url + "register")
		else {
			return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
		}
		
		let body = RegisterBody(login: login, password: password, user: user)
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try? JSONEncoder().encode(body)
		
		return URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response -> String in
				guard
					let httpResponse = response as? HTTPURLResponse,
					httpResponse.statusCode == 200,
					let json = try? JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any>,
					let token = json["token"] as? String
				else {
					throw URLError(.badServerResponse)
				}
				return token
			}
			.eraseToAnyPublisher()
	}
	
	func login(login: String, password: String) -> AnyPublisher<String, Error> {
		guard
			let url = URL(string: url + "login")
		else {
			return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
		}
		
		let body = ["login": login, "password": password]
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
		
		return URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response -> String in
				guard
					let httpResponse = response as? HTTPURLResponse,
					httpResponse.statusCode == 200,
					let json = try? JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any>,
					let token = json["token"] as? String
				else {
					throw URLError(.badServerResponse)
				}
				return token
			}
			.eraseToAnyPublisher()
	}
	
	func checkToken(_ token: String) -> AnyPublisher<Bool, Error> {
		guard
			let url = URL(string: url + "verify_token")
		else {
			return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
		}
		
		var request = URLRequest(url: url)
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let body = ["token": token]
		request.httpMethod = "POST"
		request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
		
		return URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response -> Bool in
				guard
					let httpResponse = response as? HTTPURLResponse,
					httpResponse.statusCode == 200
				else {
					return false
				}
				return true
			}
			.eraseToAnyPublisher()
	}
}

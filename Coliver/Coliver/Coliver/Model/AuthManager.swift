//
//  AuthManager.swift
//  Coliver
//
//  Created by Никита Шляхов on 22.05.2023.
//

import Foundation
import Combine

protocol AuthManagerProtocol {
	func login(login: String, password: String) -> AnyPublisher<String, Error>
	func register(_ user: UserModel, login: String, password: String) -> AnyPublisher<String, Error>
	func checkToken() -> AnyPublisher<Bool, Never>
}

final class AuthManager: AuthManagerProtocol {
	
	// MARK: - Types
	
	enum AuthStatus {
		case notDefined
		case authed
		case needLogin
	}
	
	private enum Constants {
		static let isFirstLaunch = "isFirstLaunch"
		static let token = "token"
	}
	
	// MARK: Properties
	
	static let shared = AuthManager()
	
	var isAuth: AuthStatus = .notDefined
	private(set) var token: String?
	
	private let authService: AuthServiceProtocol
	private var cancellables: Set<AnyCancellable> = []
	
	// MARK: - Initialization
	
	init(authService: AuthServiceProtocol = AuthService()) {
		self.authService = authService
		checkFirstLaunch()
	}
	
	// MARK: - Methods
	
	func login(login: String, password: String) -> AnyPublisher<String, Error> {
		return Future<String, Error> { [weak self] promise in
			guard let self else { return }
			
			authService.login(login: login, password: password)
				.receive(on: DispatchQueue.main)
				.sink(receiveCompletion: { completion in
					if case let .failure(error) = completion {
						promise(.failure(error))
					}
				}, receiveValue: { token in
					self.token = token
					self.saveTokenToKeychain(token)
					promise(.success(token))
				})
				.store(in: &cancellables)
		}
		.eraseToAnyPublisher()
	}
	
	func register(_ user: UserModel, login: String, password: String) -> AnyPublisher<String, Error> {
		return Future<String, Error> { [weak self] promise in
			guard let self else { return }
			
			authService.register(user: user, login: login, password: password)
				.receive(on: DispatchQueue.main)
				.sink(receiveCompletion: { completion in
					if case let .failure(error) = completion {
						promise(.failure(error))
					}
				}, receiveValue: { token in
					self.token = token
					self.saveTokenToKeychain(token)
					promise(.success(token))
				})
				.store(in: &cancellables)
		}
		.eraseToAnyPublisher()
	}
	
	
	func checkToken() -> AnyPublisher<Bool, Never> {
		return Future<Bool, Never> { [weak self] promise in
			guard
				let self,
				let token = getTokenFromKeychain()
			else {
				print("Token not found")
				return
			}
			
			authService.checkToken(token)
				.receive(on: DispatchQueue.main)
				.sink(receiveCompletion: { completion in
					if case let .failure(error) = completion {
						print("Token Verification Error:", error)
					}
				}, receiveValue: { isValid in
					if isValid {
						self.token = token
						self.isAuth = .authed
					} else {
						self.isAuth = .needLogin
					}
					promise(.success(self.isAuth == .authed))
				})
				.store(in: &cancellables)
		}
		.eraseToAnyPublisher()
	}
	
	private func checkFirstLaunch() {
		let isFirstLaunch = UserDefaults.standard.object(forKey: Constants.isFirstLaunch) as? Bool
		if isFirstLaunch ?? true {
			clearKeychain()
			UserDefaults.standard.set(false, forKey: Constants.isFirstLaunch)
		}
	}
	
	private func saveTokenToKeychain(_ token: String) {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: Constants.token,
			kSecValueData as String: token.data(using: .utf8)!,
			kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
		]
		SecItemDelete(query as CFDictionary)
		
		let status = SecItemAdd(query as CFDictionary, nil)
		if status != errSecSuccess {
			print("Failed to save token to Keychain with status: \(status)")
		}
	}
	
	private func getTokenFromKeychain() -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: Constants.token,
			kSecMatchLimit as String: kSecMatchLimitOne,
			kSecReturnData as String: true
		]
		
		var item: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &item)
		if status == errSecSuccess, let data = item as? Data, let token = String(data: data, encoding: .utf8) {
			return token
		} else {
			print("Failed to retrieve token from Keychain with status: \(status)")
			return nil
		}
	}
	
	private func clearKeychain() {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: Constants.token
		]
		let status = SecItemDelete(query as CFDictionary)
		if status != errSecSuccess {
			print("Failed to clear Keychain with status: \(status)")
		}
	}
}

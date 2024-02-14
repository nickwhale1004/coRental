//
//  AuthManager.swift
//  Coliver
//
//  Created by Никита Шляхов on 22.05.2023.
//

import Foundation
import Combine

protocol AuthManagerProtocol {
	var token: String? { get }
	
    func login(login: String, password: String) async throws -> String
    func register(_ user: UserModel, login: String, password: String) async throws -> String
    func checkToken() async -> Bool
}

final class AuthManager: AuthManagerProtocol {
	
	// MARK: - Types
	
	private enum Constants {
		static let isFirstLaunch = "isFirstLaunch"
		static let token = "token"
	}
	
	// MARK: Properties
	
	static let shared = AuthManager()
	
	private(set) var token: String?
	
	private let authService: AuthServiceProtocol
	
	// MARK: - Initialization
	
	init(authService: AuthServiceProtocol = AuthService()) {
		self.authService = authService
		checkFirstLaunch()
	}
	
	// MARK: - Methods
	
	func login(login: String, password: String) async throws -> String {
        token = try await authService.login(login: login, password: password)
        saveTokenToKeychain(token!)
        return token!
	}
	
	func register(_ user: UserModel, login: String, password: String) async throws -> String {
        token = try await authService.register(user: user, login: login, password: password)
        saveTokenToKeychain(token!)
        return token!
	}
	
	func checkToken() async -> Bool {
        guard let token = getTokenFromKeychain() else {
            print("Token not found")
            return false
        }
        do {
            if try await authService.checkToken(token) {
                self.token = token
            }
            return true
        } catch {
            print("Token Verification Error:", error)
            clearKeychain()
            return false
        }
	}
	
	private func checkFirstLaunch() {
		let isFirstLaunch = UserDefaults.standard.object(forKey: Constants.isFirstLaunch) as? Bool
		if isFirstLaunch ?? true {
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

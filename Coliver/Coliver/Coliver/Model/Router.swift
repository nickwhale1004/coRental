//
//  Router.swift
//  Coliver
//
//  Created by Никита Шляхов on 15.05.2023.
//

import Foundation

enum Route: Hashable {
	case welcome
	case login
	case register(_ user: UserModel)
	case completeRegistration(_ user: UserModel)
	case main
    case chat(id: Int)
}

final class Router: ObservableObject {
	
	@Published var path = [Route]()
	@Published var rootView = Route.welcome
	
	// MARK: - LoginRegister

	func showWelcome() {
		path.append(.welcome)
	}
	
	func showLogin() {
		path.append(.login)
	}
	
	func showRegister(_ user: UserModel) {
		path.append(.register(user))
	}
	
	func showCompleteRegistration(_ user: UserModel) {
		path.append(.completeRegistration(user))
	}
	
	// MARK: - Main
	
	func showMain() {
		path = []
		rootView = .main
	}
	
	func backToRoot() {
		path.removeAll()
	}
	
	func back() {
		path.removeLast()
	}
    
    // MARK: - Chat
    
    func showChat(id: Int) {
        path.append(.chat(id: id))
    }
}

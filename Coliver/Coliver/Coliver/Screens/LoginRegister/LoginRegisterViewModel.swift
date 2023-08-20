//
//  LoginRegisterViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 15.05.2023.
//

import Foundation
import Combine

final class LoginRegisterViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum Mode: Hashable {
		case login
		case register(profile: UserModel)
	}
	
	enum State: StateProtocol {
		case start
		case valid
		case invalid(email: Bool, password: Bool, passwordRepeat: Bool)
		case authed
	}
	
	enum Event: EventProtocol {
		case validated
		case unvalidated(email: Bool, password: Bool, passwordRepeat: Bool)
		case authed
	}
	
	// MARK: - Properties
	
	let mode: Mode
	var router: Router?
	
	lazy var title = mode == .login ? "Вход": "Регистрация"
	lazy var nextButtonTitle = mode == .login ? "Войти": "Зарегистрироваться"
	
	@Published var email = ""
	@Published var password = ""
	@Published var passwordRepeat = ""
	
	@Published private(set) var state: State = .start
	
	@Published var isEmailInvalid = false
	@Published var isPasswordInvalid = false
	@Published var isPasswordRepeatInvalid = false
	
	private(set) var stateMachine = StateMachine<State, Event>(state: .start)
	private var cancellables = [AnyCancellable]()
	
	private var valEmail = Validator(mode: .email)
	private var valPassword = Validator(mode: .password)
	
	private let authManager: AuthManagerProtocol
	
	// MARK: - Initialization
	
	init(
		mode: Mode,
		authManager: AuthManagerProtocol = AuthManager.shared
	) {
		self.mode = mode
		self.authManager = authManager
		
		stateMachine.reducer = self
		stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			state = newState
			
			switch state {
			case let .invalid(email, password, passwordRepeat):
				isEmailInvalid = email
				isPasswordInvalid = password
				isPasswordRepeatInvalid = passwordRepeat
				
			case .valid:
				auth()
				
			case .authed:
				router?.showMain()
				
			default:
				break
			}
		}
		.store(in: &cancellables)
	}
	
	// MARK: - Methods
	
	func authButtonPressed() {
		validate()
	}
	
	private func validate() {
		let emailValid = valEmail.isValid(email)
		let passwordValid = valPassword.isValid(password)
		let passwordRepeatValid = passwordRepeat == password || mode == .login
		
		if emailValid && passwordValid && passwordRepeatValid {
			stateMachine.tryEvent(.validated)
		} else {
			stateMachine.tryEvent(
				.unvalidated(
					email: !emailValid,
					password: !passwordValid,
					passwordRepeat: !passwordRepeatValid
				)
			)
		}
	}
	
	private func auth() {
		if mode == .login {
			login()
		} else {
			register()
		}
	}
	
	private func login() {
		authManager.login(login: email, password: password)
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self, case let .failure(error) = completion else { return }
				
				print("Неуспешная авторизация: \(error)")
				stateMachine.tryEvent(.unvalidated(email: true, password: true, passwordRepeat: true))
				
			} receiveValue: { [weak self] token in
				guard let self else { return }
				
				print("Успешная авторизация. Токен:", token)
				stateMachine.tryEvent(.authed)
			}
			.store(in: &cancellables)
	}
	
	private func register() {
		guard case let .register(user) = mode else { return }
		
		authManager.register(user, login: email, password: password)
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self, case let .failure(error) = completion else { return }
				
				print("Неуспешная регистрация: \(error)")
				stateMachine.tryEvent(.unvalidated(email: true, password: true, passwordRepeat: true))
				
			} receiveValue: { [weak self] token in
				guard let self else { return }
				
				print("Успешная регистрация. Токен:", token)
				stateMachine.tryEvent(.authed)
			}
			.store(in: &cancellables)
	}
}

// MARK: - StateMachineDelegate

extension LoginRegisterViewModel: StateMachineReducer {
	func reduce(for event: EventProtocol) -> (any StateProtocol)? {
		guard let event = event as? Event else { return nil }
		
		switch event {
		case .validated:
			return State.valid
		case let .unvalidated(email, password, passwordRepeat):
			return State.invalid(email: email, password: password, passwordRepeat: passwordRepeat)
		case .authed:
			return State.authed
		}
	}
}


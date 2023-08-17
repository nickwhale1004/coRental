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
		case register(_ user: UserModel)
	}
	
	enum State: Equatable {
		case start
		case valid
		case invalid(email: Bool, password: Bool, passwordRepeat: Bool)
		case authed
	}
	
	enum Event {
		case validated
		case unvalidated(email: Bool, password: Bool, passwordRepeat: Bool)
		case authed
	}
	
	// MARK: - Properties
	
	let mode: Mode
	
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
		
		stateMachine.delegate = self
		stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			self.state = newState
			
			switch self.state {
			case let .invalid(email, password, passwordRepeat):
				self.isEmailInvalid = email
				self.isPasswordInvalid = password
				self.isPasswordRepeatInvalid = passwordRepeat
				
			default:
				break
			}
		}
		.store(in: &cancellables)
	}
	
	// MARK: - Methods
	
	func validate() {
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
	
	func auth() {
		if mode == .login {
			login()
		} else {
			register()
		}
	}
	
	private func login() {
		authManager.login(login: email, password: password)
			.receive(on: DispatchQueue.main)
			.sink(
				receiveCompletion: { [weak self] completion in
					guard let self else { return }
					
					if case let .failure(error) = completion {
						print("Неуспешная авторизация: \(error)")
						self.stateMachine.tryEvent(.unvalidated(email: true, password: true, passwordRepeat: true))
					}
				},
				receiveValue: { [weak self] token in
					guard let self else { return }
					
					print("Успешная авторизация. Токен:", token)
					self.stateMachine.tryEvent(.authed)
				})
			.store(in: &cancellables)
	}
	
	private func register() {
		guard case let .register(user) = mode else { return }
		
		authManager.register(user, login: email, password: password)
			.receive(on: DispatchQueue.main)
			.sink(
				receiveCompletion: { [weak self] completion in
					guard let self else { return }
					
					if case let .failure(error) = completion {
						print("Неуспешная авторизация: \(error)")
						self.stateMachine.tryEvent(.unvalidated(email: true, password: true, passwordRepeat: true))
					}
				},
				receiveValue: { [weak self] token in
					guard let self else { return }
					
					print("Успешная регистрация. Токен:", token)
					self.stateMachine.tryEvent(.authed)
				})
			.store(in: &cancellables)
	}
}

// MARK: - StateMachineDelegate

extension LoginRegisterViewModel: StateMachineDelegate {
	func nextState(for event: any EventProtocol) -> (any StateProtocol)? {
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


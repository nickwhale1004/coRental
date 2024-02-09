//
//  LoginRegisterViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 14.05.2023.
//

import Foundation
import Combine
import SwiftUI

final class EditProfileViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum Mode {
		case welcome
		case edit(profile: Binding<UserModel?>)
	}
	
	enum State: StateProtocol {
		case alreadyHasAccount
		case createAccountNotChecked
		case createAccountInvalid(name: Bool, lastName: Bool, age: Bool, gender: Bool)
		case createAccountValid
		case saved
		case error
	}
	
	enum Event: EventProtocol {
		case stopTyping
		case startTyping
		case validated
		case saved
		case error
		case invalidated(name: Bool, lastName: Bool, age: Bool, gender: Bool)
	}
	
	// MARK: - Properties
	
	@Published var firstName = "" {
		didSet {
			checkIsTyping()
			validate(false)
		}
	}
	@Published var lastName = "" {
		didSet {
			checkIsTyping()
			validate(false)
		}
	}
	@Published var thirdName = ""{
		didSet {
			checkIsTyping()
			validate(false)
		}
	}
	@Published var age: Int? {
		didSet {
			checkIsTyping()
			validate(false)
		}
	}
	@Published var gender: Gender? {
		didSet {
			checkIsTyping()
			validate(false)
		}
	}
	@Published var about = ""{
		didSet {
			checkIsTyping()
			validate(false)
		}
	}
	
	@Published var isNameInvalid: Bool = false
	@Published var isLastNameInvalid: Bool = false
	@Published var isAgeInvalid: Bool = false
	@Published var isGenderInvalid: Bool = false
	
	@Published var isLoginButtonHidden: Bool = false
	@Published var isRegisterButtonHidden: Bool = true
	@Published var isButtonEnabled: Bool = true
	
	@Published var saveButtonTitle = "Сохранить"
	
	var router: Router?
	let mode: Mode
	
	lazy var title = mode == .welcome ? "Расскажите о себе" : "Профиль"
	lazy var isSaveButtonHidden = mode == .welcome
	
	private(set) var state: State = .alreadyHasAccount
	private(set) var stateMachine = StateMachine<State, Event>(state: .alreadyHasAccount)
	
	private var cancellables = [AnyCancellable]()
	
	private var valName = Validator(mode: .namePart)
	private let userService: UserServiceProtocol
	
	// MARK: - Initialzation
	
	init(mode: Mode, userService: UserServiceProtocol = UserService()) {
		self.mode = mode
		self.userService = userService
		
		setupDefaultFields()
		setupStateMachine()
	}
	
	// MARK: - Methods
	
	func saveButtonPressed(_ isEnabled: Bool) {
		guard case let .edit(profile) = mode else { return }
		
		if !isEnabled {
			validate()
		} else {
			let user = UserModel(
                firstName: firstName,
				lastName: lastName,
				thirdName: thirdName,
				age: age ?? 0,
				gender: gender ?? .male,
				about: about,
				house: profile.wrappedValue?.house,
				search: profile.wrappedValue?.search
			)
			profile.wrappedValue = user
			saveUser()
		}
	}
	
	func loginButtonPressed(_ isEnabled: Bool) {
		router?.showLogin()
	}
	
	func registerButtonPressed(_ isEnabled: Bool) {
		if !isEnabled {
			validate()
		} else {
			let user = UserModel(
				firstName: firstName,
				lastName: lastName,
				thirdName: thirdName,
				age: age ?? 0,
				gender: gender ?? .male,
				about: about
			)
			router?.showCompleteRegistration(user)
		}
	}
	
	private func saveUser() {
		guard case let .edit(profile) = mode, let user = profile.wrappedValue else { return }
		
        Task { @MainActor in
            do {
                try await userService.updateUser(user)
                stateMachine.tryEvent(.saved)
            } catch {
                stateMachine.tryEvent(.error)
            }
        }
	}
	
	private func setupStateMachine() {
		stateMachine.reducer = self
		stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			state = newState
			
			switch state {
			case let .createAccountInvalid(name, lastName, age, gender):
				setCreateAccountInvalid(name: name, lastName: lastName, age: age, gender: gender)
				
			case .alreadyHasAccount:
				setAlreadyHasAccountState()
				
			case .createAccountNotChecked:
				setCreateAccountNotCheckedState()
				
			case .createAccountValid:
				setCreateAccountValid()
				
			case .saved:
				setSaved()
				
			case .error:
				setError()
			}
		}
		.store(in: &cancellables)
	}
	
	private func setupDefaultFields() {
		guard case let .edit(profile) = mode else { return }
		
		firstName = profile.wrappedValue?.firstName ?? ""
		lastName = profile.wrappedValue?.lastName ?? ""
		thirdName = profile.wrappedValue?.thirdName ?? ""
		age = profile.wrappedValue?.age
		gender = profile.wrappedValue?.gender
		about = profile.wrappedValue?.about ?? ""
	}
	
	private func validate(_ highlight: Bool = true) {
		let isNameValid = valName.isValid(firstName)
		let isLastNameValid = valName.isValid(lastName)
		let isAgeValid = age != nil
		let isGenderValid = gender != nil
		
		if isNameValid && isLastNameValid && isAgeValid &&  isGenderValid {
			stateMachine.tryEvent(.validated)
		} else if highlight {
			stateMachine.tryEvent(
				.invalidated(
					name: !isNameValid,
					lastName: !isLastNameValid,
					age: !isAgeValid,
					gender: !isGenderValid
				)
			)
		}
	}
	
	@discardableResult
	private func checkIsTyping() -> Bool {
		let isTyping = firstName.isEmpty && lastName.isEmpty && age == nil && thirdName.isEmpty && about.isEmpty
		
		if isTyping {
			stateMachine.tryEvent(.stopTyping)
		} else {
			stateMachine.tryEvent(.startTyping)
		}
		return isTyping
	}
}

// MARK: - States

extension EditProfileViewModel {
	private func setCreateAccountInvalid(name: Bool, lastName: Bool, age: Bool, gender: Bool) {
		isNameInvalid = name
		isLastNameInvalid = lastName
		isAgeInvalid = age
		isGenderInvalid = gender
		
		isLoginButtonHidden = true
		isRegisterButtonHidden = false
		
		isButtonEnabled = false
		saveButtonTitle = "Сохранить"
	}
	
	private func setAlreadyHasAccountState() {
		isNameInvalid = false
		isLastNameInvalid = false
		isAgeInvalid = false
		isGenderInvalid = false
		
		isLoginButtonHidden = false
		isRegisterButtonHidden = true
		
		isButtonEnabled = false
		saveButtonTitle = "Сохранить"
	}
	
	private func setCreateAccountNotCheckedState() {
		isNameInvalid = false
		isLastNameInvalid = false
		isAgeInvalid = false
		isGenderInvalid = false
		
		isLoginButtonHidden = true
		isRegisterButtonHidden = false
		
		isButtonEnabled = false
		saveButtonTitle = "Сохранить"
	}
	
	private func setCreateAccountValid() {
		isNameInvalid = false
		isLastNameInvalid = false
		isAgeInvalid = false
		isGenderInvalid = false
		
		isLoginButtonHidden = true
		isRegisterButtonHidden = false
		
		isButtonEnabled = true
		saveButtonTitle = "Сохранить"
	}
	
	private func setSaved() {
		isNameInvalid = false
		isLastNameInvalid = false
		isAgeInvalid = false
		isGenderInvalid = false
		
		isLoginButtonHidden = true
		isRegisterButtonHidden = false
		
		isButtonEnabled = false
		saveButtonTitle = "Сохранено!"
	}
	
	private func setError() {
		isNameInvalid = false
		isLastNameInvalid = false
		isAgeInvalid = false
		isGenderInvalid = false
		
		isLoginButtonHidden = true
		isRegisterButtonHidden = false
		
		isButtonEnabled = false
		saveButtonTitle = "Ошибка!"
	}
}

// MARK: - StateMachineDelegate

extension EditProfileViewModel: StateMachineReducer {
	func reduce(for event: EventProtocol) -> (any StateProtocol)? {
		switch event as? Event {
		case .stopTyping:
			return State.alreadyHasAccount
			
		case .startTyping:
			return State.createAccountNotChecked
			
		case .validated:
			if state != .saved {
				return State.createAccountValid
			} else {
				return state
			}
			
		case let .invalidated(name, lastName, age, gender):
			return State.createAccountInvalid(name: name, lastName: lastName, age: age, gender: gender)
			
		case .error:
			return State.error
		
		case .saved:
			return State.saved
			
		default:
			return nil
		}
	}
}

// MARK: - Mode+Equatable

extension EditProfileViewModel.Mode: Equatable {
	static func == (lhs: EditProfileViewModel.Mode, rhs: EditProfileViewModel.Mode) -> Bool {
		switch lhs {
		case .welcome:
			switch rhs {
			case .welcome:
				return true
			default:
				return false
			}
		default:
			switch rhs {
			case .welcome:
				return false
			default:
				return true
			}
		}
	}
}

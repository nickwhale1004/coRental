//
//  LoginRegisterViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 14.05.2023.
//

import Foundation
import Combine

final class WelcomeViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum State: Equatable {
		case alreadyHasAccount
		case createAccountNotChecked
		case createAccountInvalid(name: Bool, lastName: Bool, age: Bool, gender: Bool)
		case createAccountValid
	}
	
	enum Event {
		case stopTyping
		case startTyping
		case validated
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
	
	@Published private(set) var state: State = .alreadyHasAccount
	
	private(set) var stateMachine = StateMachine<State, Event>(state: .alreadyHasAccount)
	private var stateCancellable: AnyCancellable?
	
	private var valName = Validator(mode: .namePart)
	
	// MARK: - Initialzation
	
	init() {
		stateMachine.delegate = self
		stateCancellable = stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			self.state = newState
			
			switch self.state {
			case let .createAccountInvalid(name, lastName, age, gender):
				self.isNameInvalid = name
				self.isLastNameInvalid = lastName
				self.isAgeInvalid = age
				self.isGenderInvalid = gender
				
			default:
				break
			}
		}
	}
	
	// MARK: - Methods
	
	func validate(_ highlight: Bool = true) {
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
	
	func getUserModel() -> UserModel {
		return UserModel(
			firstName: firstName,
			lastName: lastName,
			thirdName: thirdName,
			age: age ?? 0,
			gender: gender ?? .male,
			about: about
		)
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

// MARK: - StateMachineDelegate

extension WelcomeViewModel: StateMachineDelegate {
	func nextState(for event: any EventProtocol) -> (any StateProtocol)? {
		guard let event = event as? Event else { return nil }
		
		switch event {
		case .stopTyping:
			return State.alreadyHasAccount
		case .startTyping:
			return State.createAccountNotChecked
		case .validated:
			return State.createAccountValid
		case let .invalidated(name, lastName, age, gender):
			return State.createAccountInvalid(name: name, lastName: lastName, age: age, gender: gender)
		}
	}
}

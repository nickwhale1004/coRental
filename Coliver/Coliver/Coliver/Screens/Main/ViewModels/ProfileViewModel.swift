//
//  ProfileViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 23.05.2023.
//

import Foundation
import Combine

final class ProfileViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum State: Equatable {
		case notChecked
		case valid
		case invalid(name: Bool, lastName: Bool, age: Bool, gender: Bool)
		case error
		case saved
	}
	
	enum Event {
		case typing
		case validated
		case invalidated(name: Bool, lastName: Bool, age: Bool, gender: Bool)
		case error
		case saved
	}
	
	// MARK: - Properties
	
	@Published var firstName = "" {
		didSet {
			validate(false)
		}
	}
	@Published var lastName = "" {
		didSet {
			validate(false)
		}
	}
	@Published var thirdName = "" {
		didSet {
			validate(false)
		}
	}
	@Published var age: Int? {
		didSet {
			validate(false)
		}
	}
	@Published var gender: Gender? {
		didSet {
			validate(false)
		}
	}
	@Published var about = "" {
		didSet {
			validate(false)
		}
	}
	
	@Published var isNameInvalid: Bool = false
	@Published var isLastNameInvalid: Bool = false
	@Published var isAgeInvalid: Bool = false
	@Published var isGenderInvalid: Bool = false
	
	@Published var buttonText = "Сохранить"
	
	@Published private(set) var state: State = .notChecked
	
	private(set) var stateMachine = StateMachine<State, Event>(state: .notChecked)
	private var cancellables = [AnyCancellable]()
	
	private var valName = Validator(mode: .namePart)
	private let userService: UserServiceProtocol
	
	// MARK: - Initialzation
	
	init(userService: UserServiceProtocol = UserService()) {
		self.userService = userService
		
		stateMachine.delegate = self
		stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			self.state = newState
			
			switch self.state {
			case let .invalid(name, lastName, age, gender):
				self.isNameInvalid = name
				self.isLastNameInvalid = lastName
				self.isAgeInvalid = age
				self.isGenderInvalid = gender
				self.buttonText = "Сохранить"
			
			case .saved:
				self.buttonText = "Сохранено!"
				
			case .error:
				self.buttonText = "Ошибка!"
				
			default:
				self.isNameInvalid = false
				self.isLastNameInvalid = false
				self.isAgeInvalid = false
				self.isGenderInvalid = false
				self.buttonText = "Сохранить"
			}
		}
		.store(in: &cancellables)
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
		} else {
			stateMachine.tryEvent(.typing)
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
	
	func saveUserModel() {
		userService.updateUser(getUserModel())
			.receive(on: DispatchQueue.main)
			.sink(
				receiveCompletion: { [weak self] completion in
					guard let self, case .failure = completion else { return }
					self.stateMachine.tryEvent(.error)
				},
				receiveValue: { [weak self] _ in
					guard let self else { return }
					self.stateMachine.tryEvent(.saved)
				})
			.store(in: &cancellables)
	}
	
	func updateUserModel(_ model: UserModel) {
		firstName = model.firstName
		lastName = model.lastName
		thirdName = model.thirdName ?? ""
		age = model.age
		gender = model.gender
		about = model.about ?? ""
	}
}

// MARK: - StateMachineDelegate

extension ProfileViewModel: StateMachineDelegate {
	func nextState(for event: any EventProtocol) -> (any StateProtocol)? {
		guard let event = event as? Event else { return nil }
		
		switch event {
		case .typing:
			return State.notChecked
		case .validated:
			return State.valid
		case let .invalidated(name, lastName, age, gender):
			return State.invalid(name: name, lastName: lastName, age: age, gender: gender)
		case .saved:
			return State.saved
		case .error:
			return State.error
		}
	}
}

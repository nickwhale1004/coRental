//
//  MainViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import Foundation
import Combine

final class MainViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum State {
		case loading
		case loaded
		case error
	}
	
	enum Event {
		case loading
		case loaded
		case error
	}
	
	// MARK: - Properties
	
	@Published var userModel: UserModel?
	
	@Published private(set) var state: State = .loading
	
	private(set) var stateMachine = StateMachine<State, Event>(state: .loading)
	private var cancellables = [AnyCancellable]()
	
	private let userService: UserServiceProtocol
	
	// MARK: - Initialzation
	
	init(userService: UserServiceProtocol = UserService()) {
		self.userService = userService
		loadUser()
		
		stateMachine.delegate = self
		stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			self.state = newState
		}
		.store(in: &cancellables)
	}
	
	// MARK: - Methods
	
	func loadUser() {
		stateMachine.tryEvent(.loading)
		
		userService.getUser()
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self, case .failure = completion else { return }
				self.stateMachine.tryEvent(.error)
				
			} receiveValue: { [weak self] model in
				guard let self else { return }
				
				self.userModel = model
				self.stateMachine.tryEvent(.loaded)
			}
			.store(in: &cancellables)
	}
}

// MARK: - StateMachineDelegate

extension MainViewModel: StateMachineDelegate {
	func nextState(for event: any EventProtocol) -> (any StateProtocol)? {
		guard let event = event as? Event else { return nil }
		
		switch event {
		case .loading:
			return State.loading
		case .loaded:
			return State.loaded
		case .error:
			return State.error
		}
	}
}

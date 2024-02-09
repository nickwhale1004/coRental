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
	
	enum State: StateProtocol {
		case loading
		case loaded
		case error
	}
	
	enum Event: EventProtocol {
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
		
		stateMachine.reducer = self
		stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			state = newState
		}
		.store(in: &cancellables)
	}
	
	// MARK: - Methods
	
	func repeatLoadButtonPressed() {
		loadUser()
	}
	
	private func loadUser() {
		stateMachine.tryEvent(.loading)
		
        Task { @MainActor in
            do {
                userModel = try await userService.getUser()
                stateMachine.tryEvent(.loaded)
            } catch {
                print(error)
                stateMachine.tryEvent(.error)
            }
        }
	}
}

// MARK: - StateMachineDelegate

extension MainViewModel: StateMachineReducer {
	func reduce(for event: EventProtocol) -> (any StateProtocol)? {
		switch event as? Event {
		case .loading:
			return State.loading
		case .loaded:
			return State.loaded
		case .error:
			return State.error
		default:
			return nil
		}
	}
}

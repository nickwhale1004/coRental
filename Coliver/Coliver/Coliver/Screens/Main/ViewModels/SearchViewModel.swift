//
//  SearchViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import SwiftUI
import Combine

final class SearchViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum State: StateProtocol {
		case loading
		case loaded
		case empty
		case error
	}
	
	enum Event: EventProtocol {
		case loading
		case loaded
		case empty
		case error
	}
	
	// MARK: - Properties
	
	private(set) var stateMachine = StateMachine<State, Event>(state: .loading)
	private var cancellables = [AnyCancellable]()
	
	@Published private(set) var state: State = .loading
	
	@Published var cellViewModels: [SearchCellViewModel] = []
	
	@Published var text: String = ""
	
	private let userService: UserServiceProtocol
	private var lastLoadedUser: UserModel?
	private var userBinding: Binding<UserModel?>
	
	// MARK: - Initialzation
	
	init(
		userBinding: Binding<UserModel?>,
		userService: UserServiceProtocol = UserService()
	) {
		self.userBinding = userBinding
		self.userService = userService
		
		stateMachine.reducer = self
		stateMachine.statePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newState in
				guard let self else { return }
				state = newState
				
				switch state {
				case .empty:
					text = "Пусто!"
					
				case .loading:
					text = "Загрузка..."
					
				case .error:
					text = "Ошибка!"
					
				default:
					break
				}
			}
			.store(in: &cancellables)
	}
	
	// MARK: - Methods
	
	func search() {
		guard userBinding.wrappedValue != lastLoadedUser else { return }
		stateMachine.tryEvent(.loading)
		
		userService.search()
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self, case .failure = completion else { return }
				stateMachine.tryEvent(.error)
				
			} receiveValue: { [weak self] userModels in
				guard let self else { return }
				
				cellViewModels = userModels.map { SearchCellViewModel($0) }
				stateMachine.tryEvent(self.cellViewModels.isEmpty ? .empty : .loaded)
			}
			.store(in: &cancellables)
		
		lastLoadedUser = userBinding.wrappedValue
	}
}

// MARK: - StateMachineDelegate

extension SearchViewModel: StateMachineReducer {
	func reduce(for event: EventProtocol) -> (any StateProtocol)? {
		guard let event = event as? Event else { return nil }
		
		switch event {
		case .loaded:
			return State.loaded
		case .loading:
			return State.loading
		case .empty:
			return State.empty
		case .error:
			return State.error
		}
	}
}

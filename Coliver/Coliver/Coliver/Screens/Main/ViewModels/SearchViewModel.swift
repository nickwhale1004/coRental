//
//  SearchViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import Foundation
import Combine

final class SearchViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum State: Equatable {
		case loading
		case loaded
		case empty
		case error
	}
	
	enum Event {
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
	
	// MARK: - Initialzation
	
	init(userService: UserServiceProtocol = UserService()) {
		self.userService = userService
		
		stateMachine.delegate = self
		stateMachine.statePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newState in
				guard let self else { return }
				self.state = newState
				
				switch self.state {
				case .empty:
					self.text = "Пусто!"
					
				case .loading:
					self.text = "Загрузка..."
					
				case .error:
					self.text = "Ошибка!"
					
				default:
					break
				}
			}
			.store(in: &cancellables)
	}
	
	// MARK: - Methods
	
	func search() {
		stateMachine.tryEvent(.loading)
		
		userService.search()
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { [weak self] completion in
				guard let self, case .failure = completion else { return }
				self.stateMachine.tryEvent(.error)
				
			}, receiveValue: { [weak self] userModels in
				guard let self else { return }
				
				self.cellViewModels = userModels.map { SearchCellViewModel($0) }
				self.stateMachine.tryEvent(self.cellViewModels.isEmpty ? .empty : .loaded)
			})
			.store(in: &cancellables)
	}
}

// MARK: - StateMachineDelegate

extension SearchViewModel: StateMachineDelegate {
	func nextState(for event: any EventProtocol) -> (any StateProtocol)? {
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

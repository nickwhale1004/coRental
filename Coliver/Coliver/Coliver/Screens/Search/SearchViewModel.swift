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
    private let chatService: ChatServiceProtocol
	private var userBinding: Binding<UserModel?>
	
	// MARK: - Initialzation
	
	init(
		userBinding: Binding<UserModel?>,
		userService: UserServiceProtocol = UserService(),
        chatService: ChatServiceProtocol = ChatService()
	) {
		self.userBinding = userBinding
		self.userService = userService
        self.chatService = chatService
		
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
	
	func onAppear() {
		loadData()
	}
    
    func writeMessageTapped(_ viewModel: SearchCellViewModel) {
        Task { @MainActor in
            do {
                try await chatService.createChat(userId: viewModel.id)
            } catch {
                stateMachine.tryEvent(.error)
            }
        }
    }
    
    func likeTapped(_ viewModel: SearchCellViewModel) {
        Task { @MainActor in
            do {
                try await userService.like(userId: viewModel.id)
                loadData()
            } catch {
                stateMachine.tryEvent(.error)
            }
        }
    }
    
    func unlikeTapped(_ viewModel: SearchCellViewModel) {
        Task { @MainActor in
            do {
                try await userService.unlike(userId: viewModel.id)
                loadData()
            } catch {
                stateMachine.tryEvent(.error)
            }
        }
    }
    
    private func loadData() {
        if cellViewModels.isEmpty {
            stateMachine.tryEvent(.loading)
        }
        
        Task { @MainActor in
            do {
                let userModels = try await userService.search()
                cellViewModels = userModels.map { SearchCellViewModel($0) }
                stateMachine.tryEvent(self.cellViewModels.isEmpty ? .empty : .loaded)
            } catch {
                stateMachine.tryEvent(.error)
            }
        }
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

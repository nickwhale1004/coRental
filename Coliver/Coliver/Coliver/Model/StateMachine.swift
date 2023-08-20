//
//  StateMachine.swift
//  Coliver
//
//  Created by Никита Шляхов on 14.05.2023.
//

import Combine

protocol StateProtocol: Equatable { }
protocol EventProtocol { }

protocol StateMachineReducer: AnyObject {
	func reduce(for event: EventProtocol) -> (any StateProtocol)?
}

final class StateMachine<State: StateProtocol, Event: EventProtocol> {
	
	// MARK: - Properties
	
	weak var reducer: StateMachineReducer?
	lazy var statePublisher = stateSubject.eraseToAnyPublisher()
	
	private var state: State {
		didSet { stateSubject.send(state) }
	}
	private let stateSubject = PassthroughSubject<State, Never>()
	
	// MARK: - Initialization
	
	init(state: State) {
		self.state = state
	}
	
	// MARK: Methods
	
	func tryEvent(_ event: Event) {
		if let state = reducer?.reduce(for: event) as? State {
			self.state = state
		}
	}
}

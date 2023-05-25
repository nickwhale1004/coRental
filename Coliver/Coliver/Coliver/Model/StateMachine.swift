//
//  StateMachine.swift
//  Coliver
//
//  Created by Никита Шляхов on 14.05.2023.
//

import Combine


typealias EventProtocol = Any
typealias StateProtocol = Any

protocol StateMachineDelegate: AnyObject {
	func nextState(for event: any EventProtocol) -> (any StateProtocol)?
}

final class StateMachine<State: StateProtocol, Event: EventProtocol> {
	
	// MARK: - Properties
	
	weak var delegate: StateMachineDelegate?
	let statePublisher: AnyPublisher<State, Never>
	
	private var state: State {
		didSet { stateSubject.send(state) }
	}
	
	private let stateSubject: PassthroughSubject<State, Never>
	
	// MARK: - Initialization
	
	init(state: State) {
		self.state = state
		self.stateSubject = PassthroughSubject<State, Never>()
		self.statePublisher = stateSubject.eraseToAnyPublisher()
	}
	
	// MARK: Methods
	
	func tryEvent(_ event: Event) {
		if let state = delegate?.nextState(for: event) as? State {
			self.state = state
		}
	}
}

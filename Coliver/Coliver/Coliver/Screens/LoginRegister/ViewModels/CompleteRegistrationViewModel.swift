//
//  CompleteRegistrationViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import Combine
import _PhotosUI_SwiftUI

final class CompleteRegistrationViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum State: Equatable {
		case hasLivingNotChecked
		case hasLivingValid
		case hasLivingInvalid(address: Bool, cost: Bool)
		case findLiving
	}
	
	enum Event {
		case selectHasLiving
		case selectFindLiving
		case hasLivingValidated
		case hasLivingInvalidated(address: Bool, cost: Bool)
	}
	
	// MARK: - Properties
	
	@Published var selection: UserFindStatus = .friend
	
	@Published var ageFrom: Int?
	@Published var ageTo: Int?
	@Published var gender: Gender?
	
	@Published var findCostFrom: Int?
	@Published var findCostTo: Int?
	
	@Published var hasAddress: String = "" {
		didSet {
			validate(false)
		}
	}
	@Published var hasCost: Int? {
		didSet {
			validate(false)
		}
	}
	
	@Published var isAddressInvalid = false
	@Published var isCostInvalid = false
	
	@Published var selectedItem: PhotosPickerItem? = nil
	@Published var uploadPublisher = PassthroughSubject<Bool, Never>()
	@Published var selectedImageData: Data? = nil

	private var user = UserModel()
	private var imageURL: String?
	
	private(set) var stateMachine = StateMachine<State, Event>(state: .hasLivingNotChecked)
	private var cancellables = [AnyCancellable]()
	
	@Published private(set) var state: State = .hasLivingNotChecked
	
	private let imageService: ImageServiceProtocol
	
	// MARK: - Initialzation
	
	init(
		_ model: UserModel,
		imageService: ImageServiceProtocol = ImageService()
	) {
		self.imageService = imageService
		
		updateUser(model)
		
		stateMachine.delegate = self
		stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			self.state = newState
			
			switch self.state {
			case let .hasLivingInvalid(address, cost):
				self.isAddressInvalid = address
				self.isCostInvalid = cost
				
			default:
				self.isAddressInvalid = false
				self.isCostInvalid = false
			}
		}
		.store(in: &cancellables)
	}
	
	// MARK: - Methods
	
	func validate(_ highlight: Bool = true) {
		let isAddressValid = !hasAddress.isEmpty
		let isCostValid = hasCost != nil
		
		if isCostValid && isAddressValid {
			stateMachine.tryEvent(.hasLivingValidated)
		} else if highlight {
			stateMachine.tryEvent(
				.hasLivingInvalidated(address: !isAddressValid, cost: !isCostValid)
			)
		} else {
			stateMachine.tryEvent(
				.selectHasLiving
			)
		}
	}
	
	func updatedUser() -> UserModel {
		if selection == .friend {
			let house = HouseModel(address: hasAddress, price: hasCost ?? 0, imageURL: imageURL)
			user.house = house
		}
		let search = SearchModel(
			type: selection,
			userAgeFrom: ageFrom,
			userAgeTo: ageTo,
			userGender: gender,
			housePriceFrom: findCostFrom,
			housePriceTo: findCostTo
		)
		user.search = search
		
		return user
	}
	
	func uploadImage() {
		guard
			let data = selectedImageData
		else {
			uploadPublisher.send(true)
			return
		}
		
		imageService.uploadImage(data)
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self, case .failure = completion else { return }
				
				print("Error upldoded image")
				self.uploadPublisher.send(false)
				
			} receiveValue: { [weak self] url in
				guard let self else { return }
				
				self.imageURL = url
				self.uploadPublisher.send(true)
			}
			.store(in: &cancellables)
	}
	
	func updateUser(_ model: UserModel) {
		user = model
		
		ageFrom = model.search?.userAgeFrom
		ageTo = model.search?.userAgeTo
		gender = model.search?.userGender
		
		findCostFrom = model.search?.housePriceFrom
		findCostTo = model.search?.housePriceTo
		
		hasAddress = model.house?.address ?? ""
		hasCost = model.house?.price
		imageURL = model.house?.imageURL
	}
}

// MARK: - StateMachineDelegate

extension CompleteRegistrationViewModel: StateMachineDelegate {
	func nextState(for event: any EventProtocol) -> (any StateProtocol)? {
		guard let event = event as? Event else { return nil }
		
		switch event {
		case .hasLivingValidated:
			return State.hasLivingValid
		case let .hasLivingInvalidated(address, cost):
			return State.hasLivingInvalid(address: address, cost: cost)
		case .selectFindLiving:
			return State.findLiving
		case .selectHasLiving:
			return State.hasLivingNotChecked
		}
	}
}

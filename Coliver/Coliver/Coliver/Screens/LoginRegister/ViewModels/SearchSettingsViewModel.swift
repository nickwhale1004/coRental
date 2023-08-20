//
//  CompleteRegistrationViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import Combine
import SwiftUI
import _PhotosUI_SwiftUI

final class SearchSettingsViewModel: ObservableObject {
	
	// MARK: - Types
	
	enum Mode {
		case completeRegistration(profile: UserModel?)
		case searchSettings(profile: Binding<UserModel?>)
	}
	
	enum State: StateProtocol {
		case hasLivingNotChecked
		case hasLivingValid
		case hasLivingInvalid(address: Bool, cost: Bool)
		case findLiving
		case error
		case saved
	}
	
	enum Event: EventProtocol {
		case selectHasLiving
		case selectFindLiving
		case hasLivingValidated
		case hasLivingInvalidated(address: Bool, cost: Bool)
		case error
		case saved
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
	
	@Published var isSaveButtonEnabled = false
	@Published var saveButtonTitle = "Сохранить"
	
	@Published var selectedPhotoItem: PhotosPickerItem? = nil {
		didSet {
			makeImage()
		}
	}
	@Published var selectedImage: UIImage? = nil

	var router: Router?
	
	private let mode: Mode
	
	private var state: State = .hasLivingNotChecked
	private(set) var stateMachine = StateMachine<State, Event>(state: .hasLivingNotChecked)
	
	private var user: Binding<UserModel?>
	private var imageURL: String?
	
	private var cancellables = [AnyCancellable]()
	private let imageService: ImageServiceProtocol
	private let userService: UserServiceProtocol
	
	// MARK: - Initialzation
	
	init(
		mode: Mode,
		imageService: ImageServiceProtocol = ImageService(),
		userService: UserServiceProtocol = UserService()
	) {
		self.mode = mode
		self.imageService = imageService
		self.userService = userService
		
		switch mode {
		case let .completeRegistration(model):
			user = Binding<UserModel?>(get: { return model }, set: { _ in })
			
		case let .searchSettings(model):
			user = model
		}
		
		setupDefaultFields()
		setupStateMachine()
	}
	
	// MARK: - Methods
	
	func saveButtonPressed(isEnabled: Bool) {
		if isEnabled {
			uploadImage { [weak self] in
				self?.goNext()
			}
		} else {
			validate()
		}
	}
	
	private func goNext() {
		guard let user = user.wrappedValue else { return }
		
		if case .completeRegistration = mode {
			router?.showRegister(user)
		} else {
			saveUserModel()
		}
	}
	
	private func saveUserModel() {
		guard let user = user.wrappedValue else { return }
		
		userService.updateUser(user)
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self, case .failure = completion else { return }
				stateMachine.tryEvent(.error)
				
			} receiveValue: { [weak self] _ in
				guard let self else { return }
				stateMachine.tryEvent(.saved)
			}
			.store(in: &cancellables)
	}
	
	private func setupStateMachine() {
		stateMachine.reducer = self
		stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			state = newState
			
			switch state {
			case let .hasLivingInvalid(address, cost):
				setHasLivingInvalid(address: address, cost: cost)
				
			case .findLiving:
				setFindLiving()
			
			case .hasLivingNotChecked:
				setHasLivingNotChecked()
			
			case .hasLivingValid:
				setHasLivingValid()
				
			case .error:
				setError()
				
			case .saved:
				setSaved()
			}
		}
		.store(in: &cancellables)
	}
	
	private func makeImage() {
		selectedPhotoItem?.loadTransferable(type: Data.self) { [weak self] completion in
			guard let self, case let .success(data) = completion, let data else { return }
			selectedImage = UIImage(data: data)
		}
	}
	
	private func validate(_ highlight: Bool = true) {
		let isAddressValid = !hasAddress.isEmpty
		let isCostValid = hasCost != nil
		
		if isCostValid && isAddressValid {
			stateMachine.tryEvent(.hasLivingValidated)
		} else if highlight {
			stateMachine.tryEvent(
				.hasLivingInvalidated(address: !isAddressValid, cost: !isCostValid)
			)
		} else {
			stateMachine.tryEvent(.selectHasLiving)
		}
	}
	
	private func updateUser(){
		if selection == .friend {
			let house = HouseModel(address: hasAddress, price: hasCost ?? 0, imageURL: imageURL)
			user.wrappedValue?.house = house
		}
		let search = SearchModel(
			type: selection,
			userAgeFrom: ageFrom,
			userAgeTo: ageTo,
			userGender: gender,
			housePriceFrom: findCostFrom,
			housePriceTo: findCostTo
		)
		user.wrappedValue?.search = search
	}
	
	private func uploadImage(_ completion: @escaping () -> Void) {
		guard
			let data = selectedImage?.pngData()
		else {
			goNext()
			return
		}
		
		imageService.uploadImage(data)
			.receive(on: DispatchQueue.main)
			.sink { result in
				guard case .failure = result else { return }
				print("Error upldoded image")
				
			} receiveValue: { [weak self] url in
				guard let self else { return }
				
				imageURL = url
				completion()
			}
			.store(in: &cancellables)
	}
	
	private func setupDefaultFields() {
		selection = user.wrappedValue?.search?.type ?? .placeAndFriend
		
		ageFrom = user.wrappedValue?.search?.userAgeFrom
		ageTo = user.wrappedValue?.search?.userAgeTo
		gender = user.wrappedValue?.search?.userGender
		
		findCostFrom = user.wrappedValue?.search?.housePriceFrom
		findCostTo = user.wrappedValue?.search?.housePriceTo
		
		hasAddress = user.wrappedValue?.house?.address ?? ""
		hasCost = user.wrappedValue?.house?.price
		imageURL = user.wrappedValue?.house?.imageURL
		
		if let imageURL {
			imageService.downloadImage(imageURL)
				.receive(on: DispatchQueue.main)
				.sink { [weak self] completion in
					guard let self, case .failure = completion else { return }
					stateMachine.tryEvent(.error)
					
				} receiveValue: { [weak self] data in
					guard let self else { return }
					selectedImage = UIImage(data: data)
				}
				.store(in: &cancellables)
		}
		
	}
}

// MARK: - States

extension SearchSettingsViewModel {
	private func setHasLivingInvalid(address: Bool, cost: Bool) {
		isSaveButtonEnabled = false
		isAddressInvalid = address
		isCostInvalid = cost
		saveButtonTitle = "Сохарнить"
	}
	
	private func setFindLiving() {
		isSaveButtonEnabled = true
		isAddressInvalid = false
		isCostInvalid = false
		saveButtonTitle = "Сохарнить"
	}
	
	private func setHasLivingNotChecked() {
		isSaveButtonEnabled = false
		isAddressInvalid = false
		isCostInvalid = false
		saveButtonTitle = "Сохарнить"
	}
	
	private func setHasLivingValid() {
		isSaveButtonEnabled = true
		isAddressInvalid = false
		isCostInvalid = false
		saveButtonTitle = "Сохарнить"
	}
	
	private func setError() {
		isSaveButtonEnabled = false
		isAddressInvalid = false
		isCostInvalid = false
		saveButtonTitle = "Ошибка!"
	}
	
	private func setSaved() {
		isSaveButtonEnabled = false
		isAddressInvalid = false
		isCostInvalid = false
		saveButtonTitle = "Сохранено!"
	}
}

// MARK: - StateMachineDelegate

extension SearchSettingsViewModel: StateMachineReducer {
	func reduce(for event: EventProtocol) -> (any StateProtocol)? {
		guard let event = event as? Event else { return nil }
		
		switch event {
		case .hasLivingValidated:
			if state != .saved {
				return State.hasLivingValid
			} else {
				return state
			}
			
		case let .hasLivingInvalidated(address, cost):
			return State.hasLivingInvalid(address: address, cost: cost)
			
		case .selectFindLiving:
			return State.findLiving
			
		case .selectHasLiving:
			return State.hasLivingNotChecked
		
		case .error:
			return State.error
		
		case .saved:
			return State.saved
		}
	}
}

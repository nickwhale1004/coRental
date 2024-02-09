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
		case notChecked
		case valid
		case invalid(address: Bool, cost: Bool)
		case error
		case saved
	}
	
	enum Event: EventProtocol {
		case notChecked
		case validated
		case invalidated(address: Bool, cost: Bool)
		case error
		case saved
	}
	
	// MARK: - Properties
	
	@Published var selection: UserFindStatus = .friend { didSet { validate() } }
	@Published var ageFrom: Int? { didSet { validate() } }
	@Published var ageTo: Int? { didSet { validate() } }
	@Published var gender: Gender? { didSet { validate() } }
	@Published var findCostFrom: Int? { didSet { validate() } }
	@Published var findCostTo: Int? { didSet { validate() } }
	
	@Published var hasAddress: String = "" { didSet { validate() } }
	@Published var hasCost: Int? { didSet { validate() } }
	
	@Published var isAddressInvalid = false
	@Published var isCostInvalid = false
	
	@Published var isSaveButtonEnabled = false
	@Published var saveButtonTitle = "Сохранить"
	
	@Published var selectedPhotoItem: PhotosPickerItem? = nil { didSet { makeImage() } }
	@Published var selectedImage: UIImage? = nil

	var router: Router?
	
	private let mode: Mode
	
	private var state: State = .notChecked
	private(set) var stateMachine = StateMachine<State, Event>(state: .notChecked)
	
	private var user: UserModel?
	private var userBinding: Binding<UserModel?>?
	private var imageUrl: String?
	
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
			user = model
			
		case let .searchSettings(model):
			user = model.wrappedValue
			userBinding = model
		}
		
		setupStateMachine()
		setupDefaultFields()
	}
	
	// MARK: - Methods
    
    func onAppear() {
        setupDefaultFields()
    }
	
	func saveButtonPressed(isEnabled: Bool) {
		if isEnabled {
            Task { @MainActor in
                await uploadImage()
                goNext()
            }
		} else {
			validate()
		}
	}
	
	private func goNext() {
		updateUser()
		guard let user else { return }
		
		if case .completeRegistration = mode {
			router?.showRegister(user)
		} else {
			saveUser()
		}
	}
	
	private func saveUser() {
		guard let user else { return }
        
        Task { @MainActor in
            do {
                try await userService.updateUser(user)
                stateMachine.tryEvent(.saved)
            } catch {
                stateMachine.tryEvent(.error)
            }
        }
	}
	
	private func setupStateMachine() {
		stateMachine.reducer = self
		stateMachine.statePublisher.sink { [weak self] newState in
			guard let self else { return }
			state = newState
			
			switch state {
			case let .invalid(address, cost):
				setInvalid(address: address, cost: cost)
			
			case .notChecked:
				setNotChecked()
			
			case .valid:
				setValid()
				
			case .error:
				setError()
				
			case .saved:
				setSaved()
			}
		}
		.store(in: &cancellables)
	}
	
	private func makeImage() {
		selectedPhotoItem?.loadTransferable(type: Data.self) { completion in
			guard case let .success(data) = completion, let data else { return }
			
			DispatchQueue.main.async {
				self.selectedImage = UIImage(data: data)
			}
		}
	}
	
	private func validate(highlight: Bool = false) {
		switch selection {
		case .friend:
			let isAddressValid = !hasAddress.isEmpty
			let isCostValid = hasCost != nil
			
			if isCostValid && isAddressValid {
				stateMachine.tryEvent(.validated)
			} else if highlight {
				stateMachine.tryEvent(
					.invalidated(address: !isAddressValid, cost: !isCostValid)
				)
			} else {
				stateMachine.tryEvent(.notChecked)
			}
			
		case .placeAndFriend:
			stateMachine.tryEvent(.validated)
		}
	}
	
	private func updateUser(){
		if selection == .friend {
			let house = HouseModel(address: hasAddress, price: hasCost ?? 0, imageUrl: imageUrl)
			user?.house = house
		}
		let search = SearchModel(
			type: selection,
			userAgeFrom: ageFrom,
			userAgeTo: ageTo,
			userGender: gender,
			housePriceFrom: findCostFrom,
			housePriceTo: findCostTo
		)
		user?.search = search
		DispatchQueue.main.async {
			self.userBinding?.wrappedValue = self.user
		}
	}
	
	private func uploadImage() async {
        guard let data = selectedImage?.pngData() else { return }
        do {
            imageUrl = try await imageService.uploadImage(data)
        } catch {
            print("Error upldoded image")
        }
	}
	
	private func setupDefaultFields() {
		selection = user?.search?.type ?? .placeAndFriend
		
		ageFrom = user?.search?.userAgeFrom
		ageTo = user?.search?.userAgeTo
		gender = user?.search?.userGender
		
		findCostFrom = user?.search?.housePriceFrom
		findCostTo = user?.search?.housePriceTo
		
		hasAddress = user?.house?.address ?? ""
		hasCost = user?.house?.price
		imageUrl = user?.house?.imageUrl
		
        if let imageUrl {
            Task { @MainActor in
                do {
                    selectedImage = try await imageService.downloadImage(imageUrl)
                } catch {
                    stateMachine.tryEvent(.error)
                }
            }
        }
	}
}

// MARK: - States

extension SearchSettingsViewModel {
	private func setInvalid(address: Bool, cost: Bool) {
		isSaveButtonEnabled = false
		isAddressInvalid = address
		isCostInvalid = cost
		saveButtonTitle = "Сохранить"
	}
	
	private func setNotChecked() {
		isSaveButtonEnabled = false
		isAddressInvalid = false
		isCostInvalid = false
		saveButtonTitle = "Сохранить"
	}
	
	private func setValid() {
		isSaveButtonEnabled = true
		isAddressInvalid = false
		isCostInvalid = false
		saveButtonTitle = "Сохранить"
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
		case .validated:
			return State.valid
			
		case let .invalidated(address, cost):
			return State.invalid(address: address, cost: cost)
			
		case .notChecked:
			return State.notChecked
		
		case .error:
			return State.error
		
		case .saved:
			return State.saved
		}
	}
}

//
//  CompleteRegistrationView.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import SwiftUI
import PhotosUI
import Combine

struct SearchSettingsView: View {
	@EnvironmentObject private var router: Router
	@StateObject private var viewModel: SearchSettingsViewModel
	
	@State private var showExistingHouseParamters: Bool
	@State private var showFindHouseParamters: Bool
	
	var body: some View {
		ZStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 30) {
					Text("Укажите Ваш текущий статус")
						.font(.system(size: 23))
						.bold()
					RadioButtonGroup(
						selection: $viewModel.selection,
						orientation: .vertical,
						items: Array(UserFindStatus.allCases)
					)
					if showExistingHouseParamters {
						existingHouseView
					}
					Text("Ваши предпочтения?")
						.font(.system(size: 23))
						.bold()
						.padding(.top, 30)
					commonParametersView
					
					if showFindHouseParamters {
						findHouseView
					}
				}
				.padding(.top, 40)
				.padding(.horizontal, 20)
			}
			.frame(maxHeight: .infinity, alignment: .top)
			
			saveButtonView
		}
		.onChange(of: viewModel.selection) { selection in
			if selection == .placeAndFriend {
				withAnimation {
					showFindHouseParamters = true
					showExistingHouseParamters = false
				}
			} else {
				withAnimation {
					showFindHouseParamters = false
					showExistingHouseParamters = true
				}
			}
		}
		.onAppear {
			viewModel.router = router
		}
		.navigationTitle("Завершение")
		.navigationBarTitleDisplayMode(.large)
		.toolbarBackground(
			Color.white,
			for: .navigationBar
		)
	}
	
	@ViewBuilder private var existingHouseView: some View {
		VStack(spacing: 30) {
			PlainTextField("Адрес Вашего жилья", text: $viewModel.hasAddress)
				.invalid($viewModel.isAddressInvalid)
			
			PlainTextField("Стоимость аренды Вашего жилья", value: $viewModel.hasCost)
				.invalid($viewModel.isCostInvalid)
			
			PhotosPicker(
				selection: $viewModel.selectedPhotoItem,
				matching: .images,
				photoLibrary: .shared()
			) {
				Text("Добавьте фото")
			}
			if let selectedImage = viewModel.selectedImage {
				Image(uiImage: selectedImage)
					.resizable()
					.scaledToFit()
					.frame(width: 250, height: 250)
			}
		}
		.transition(.move(edge: .top).combined(with: .opacity))
		.padding(.top, 10)
	}
	
	@ViewBuilder private var findHouseView: some View {
		VStack(spacing: 30) {
			PlainTextField("Стоимость аренды от 0 рублей", value: $viewModel.findCostFrom)
			PlainTextField("До 1 000 000 рублей", value: $viewModel.findCostTo)
		}
		.transition(.move(edge: .bottom).combined(with: .opacity))
		.padding(.top, 10)
	}
	
	@ViewBuilder private var commonParametersView: some View {
		PlainTextField("Возраст сожителя от 18 лет", value: $viewModel.ageFrom)
		PlainTextField("До 100 лет", value: $viewModel.ageTo)
		PickerTextField("Пол сожителя", items: Array(Gender.allCases), selection: $viewModel.gender)
	}
	
	@ViewBuilder private var saveButtonView: some View {
		VStack(spacing: 30) {
			Spacer()
			RoundedButton(
				text: viewModel.saveButtonTitle,
				action: viewModel.saveButtonPressed
			)
			.enabled(viewModel.isSaveButtonEnabled)
			.padding(.bottom, 30)
		}
	}
	
	// MARK: - Initialization
	
	init(mode: SearchSettingsViewModel.Mode) {
		let model = SearchSettingsViewModel(mode: mode)
		_viewModel = StateObject(wrappedValue: model)
		
		showFindHouseParamters = model.selection == .placeAndFriend
		showExistingHouseParamters = model.selection == .friend
	}
}

struct SearchSettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SearchSettingsView(mode: .completeRegistration(profile: UserModel()))
	}
}

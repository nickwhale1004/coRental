//
//  CompleteRegistrationView.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import SwiftUI
import PhotosUI
import Combine

struct CompleteRegistrationView: View {
	@EnvironmentObject private var router: Router
	@StateObject private var viewModel: CompleteRegistrationViewModel
	
	@State private var showExistingHouseParamters: Bool = true
	@State private var showFindHouseParamters: Bool = false
	
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
						VStack(spacing: 30) {
							PlainTextField("Адрес Вашего жилья", text: $viewModel.hasAddress)
								.invalid($viewModel.isAddressInvalid)
							PlainTextField("Стоимость аренды Вашего жилья", value: $viewModel.hasCost)
								.invalid($viewModel.isCostInvalid)
							PhotosPicker(
								selection: $viewModel.selectedItem,
								matching: .images,
								photoLibrary: .shared()
							) {
								Text("Добавьте фото")
							}
							.onChange(of: viewModel.selectedItem) { newItem in
								Task {
									if let data = try? await newItem?.loadTransferable(type: Data.self) {
										viewModel.selectedImageData = data
									}
								}
							}
							
							if let selectedImageData = viewModel.selectedImageData,
							   let uiImage = UIImage(data: selectedImageData) {
								Image(uiImage: uiImage)
									.resizable()
									.scaledToFit()
									.frame(width: 250, height: 250)
							}
						}
						.transition(.move(edge: .top).combined(with: .opacity))
						.padding(.top, 10)
					}
					
					Text("Ваши предпочтения?")
						.font(.system(size: 23))
						.bold()
						.padding(.top, 30)
					
					PlainTextField("Возраст сожителя от 18 лет", value: $viewModel.ageFrom)
					PlainTextField("До 100 лет", value: $viewModel.ageTo)
					PickerTextField("Пол сожителя", items: Array(Gender.allCases), selection: $viewModel.gender)
					
					if showFindHouseParamters {
						VStack(spacing: 30) {
							PlainTextField("Стоимость аренды от 0 рублей", value: $viewModel.findCostFrom)
							PlainTextField("До 1 000 000 рублей", value: $viewModel.findCostTo)
						}
						.transition(.move(edge: .bottom).combined(with: .opacity))
						.padding(.top, 10)
					}
				}
				.padding(.top, 40)
				.padding(.horizontal, 20)
			}
			.frame(maxHeight: .infinity, alignment: .top)
			
			VStack(spacing: 30) {
				Spacer()
				RoundedButton(text: "Сохранить") { isEnabled in
					if isEnabled {
						viewModel.uploadImage()
					} else {
						viewModel.validate()
					}
				}
				.enabled(viewModel.state == .hasLivingValid || viewModel.state == .findLiving)
			}
		}
		.onChange(of: viewModel.selection) { selection in
			if selection == .placeAndFriend {
				viewModel.stateMachine.tryEvent(.selectFindLiving)
				withAnimation {
					showFindHouseParamters = true
					showExistingHouseParamters = false
				}
			} else {
				withAnimation {
					viewModel.stateMachine.tryEvent(.selectHasLiving)
					showFindHouseParamters = false
					showExistingHouseParamters = true
				}
			}
		}
		.onReceive(viewModel.uploadPublisher) { isOK in
			if isOK {
				let user = viewModel.updatedUser()
				router.showRegister(user)
			}
		}
		.navigationTitle("Завершение")
		.navigationBarTitleDisplayMode(.large)
		.toolbarBackground(
			Color.white,
			for: .navigationBar
		)
	}
	
	// MARK: - Initialization
	
	init(_ user: UserModel) {
		_viewModel = StateObject(wrappedValue: CompleteRegistrationViewModel(user))
	}
}

struct CompleteRegistrationView_Previews: PreviewProvider {
	static var previews: some View {
		CompleteRegistrationView(UserModel())
	}
}

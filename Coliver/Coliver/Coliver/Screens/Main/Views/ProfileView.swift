//
//  ProfileView.swift
//  Coliver
//
//  Created by Никита Шляхов on 23.05.2023.
//

import SwiftUI

struct ProfileView: View {
	
	// MARK: - Properties
	
	@EnvironmentObject var router: Router
	@StateObject var viewModel = ProfileViewModel()
	@Binding var userModel: UserModel
	
	// MARK: - View
	
    var body: some View {
		ZStack {
			ScrollView(.vertical) {
				VStack(alignment: .leading, spacing: 30) {
					Text("Профиль")
						.font(.system(size: 23))
						.bold()
					PlainTextField(
						"Имя",
						text: $viewModel.firstName,
						isRequired: true
					)
					.invalid($viewModel.isNameInvalid)
					
					PlainTextField(
						"Фамилия",
						text: $viewModel.lastName,
						isRequired: true
					)
					.invalid($viewModel.isLastNameInvalid)
					
					PlainTextField(
						"Отчество",
						text: $viewModel.thirdName
					)
					
					PickerTextField(
						"Пол",
						items: Array(Gender.allCases),
						selection: $viewModel.gender,
						isRequired: true
					)
					
					PlainTextField(
						"Возраст",
						value: $viewModel.age,
						isRequired: true
					)
					.invalid($viewModel.isAgeInvalid)
					
					PlainTextField(
						"Расскажите немного с себе...",
						text: $viewModel.about,
						size: .extended
					)
				}
				.padding(.top, 40)
			}
			.padding(.horizontal, 20)
			
			VStack {
				Spacer()
				RoundedButton(text: viewModel.buttonText) { isEnabled in
					if isEnabled {
						userModel = viewModel.getUserModel()
						viewModel.saveUserModel()
					} else if viewModel.state == .notChecked {
						viewModel.validate()
					}
				}
				.enabled(viewModel.state == .valid)
				.padding(.bottom, 30)
			}
		}
		.onChange(of: userModel) { model in
			viewModel.updateUserModel(model)
		}
    }
	
	// MARK: - Initialization
	
	init(_ model: Binding<UserModel>) {
		_userModel = model
	}
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
		let user = Binding<UserModel>.constant(.init())
        ProfileView(user)
    }
}

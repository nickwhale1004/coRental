//
//  LoginRegisterView.swift
//  Coliver
//
//  Created by Никита Шляхов on 12.05.2023.
//

import SwiftUI

struct EditProfileView: View {
	@EnvironmentObject private var router: Router
	@ObservedObject private var viewModel: EditProfileViewModel
	
	var body: some View {
		ZStack {
			ScrollView(.vertical) {
				VStack(alignment: .leading, spacing: 30) {
					Text("Расскажите о себе!")
						.font(.system(size: 23))
						.bold()
					textFields
				}
				.padding(.top, 40)
			}
			.padding(.horizontal, 20)
			
			if viewModel.isSaveButtonHidden {
				loginButton
				registerButton
			} else {
				saveButton
			}
		}
		.onAppear {
			viewModel.router = router
		}
		.toolbarBackground(
			Color.white,
			for: .navigationBar
		)
	}
	
	@ViewBuilder private var textFields: some View {
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
	
	@ViewBuilder private var loginButton: some View {
		VStack {
			Spacer()
			RoundedButton(
				text: "У меня уже есть аккаунт",
				action: viewModel.loginButtonPressed
			)
			.opacity(viewModel.isLoginButtonHidden ? 0 : 1)
			.offset(viewModel.isLoginButtonHidden ? CGSize(width: 0, height: 100) : .zero)
			.animation(.easeInOut, value: viewModel.isLoginButtonHidden)
		}
	}
	
	@ViewBuilder private var registerButton: some View {
		VStack {
			Spacer()
			RoundedButton(
				text: "Регистрация",
				style: .black,
				action: viewModel.registerButtonPressed
			)
			.enabled(viewModel.isButtonEnabled)
			.opacity(viewModel.isRegisterButtonHidden ? 0 : 1)
			.offset(viewModel.isRegisterButtonHidden ? CGSize(width: 0, height: 100) : .zero)
			.animation(.easeInOut, value: viewModel.isRegisterButtonHidden)
		}
	}
	
	@ViewBuilder private var saveButton: some View {
        VStack(spacing: 16) {
			Spacer()
            Button {
                viewModel.logoutTapped()
            } label: {
                Text("Выйти")
                    .underline()
            }
            RoundedButton(text: viewModel.saveButtonTitle) { isEnabled in
                viewModel.saveButtonPressed(isEnabled)
            }
			.enabled(viewModel.isButtonEnabled)
			.padding(.bottom, 30)
		}
	}
	
	// MARK: - Initialization
	
	init(mode: EditProfileViewModel.Mode) {
		_viewModel = ObservedObject(wrappedValue: EditProfileViewModel(mode: mode))
	}
}

struct WelcomeView_Previews: PreviewProvider {
	static var previews: some View {
		EditProfileView(mode: .welcome)
	}
}

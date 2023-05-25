//
//  LoginRegisterView.swift
//  Coliver
//
//  Created by Никита Шляхов on 12.05.2023.
//

import SwiftUI

struct WelcomeView: View {
	
	@EnvironmentObject private var router: Router
	@StateObject private var viewModel = WelcomeViewModel()
	
	var body: some View {
		ZStack {
			ScrollView(.vertical) {
				VStack(alignment: .leading, spacing: 30) {
					Text("Расскажите о себе!")
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
				RoundedButton(text: "У меня уже есть аккаунт") { _ in
					router.showLogin()
				}
				.opacity(viewModel.state == .alreadyHasAccount ? 1 : 0)
				.offset(
					viewModel.state == .alreadyHasAccount ?
						.zero : CGSize(width: 0, height: 100)
				)
				.animation(.easeInOut, value: viewModel.state)
			}
			VStack {
				Spacer()
				RoundedButton(text: "Регистрация", style: .black) { isEnabled in
					if !isEnabled {
						viewModel.validate()
					} else {
						let user = viewModel.getUserModel()
						router.showCompleteRegistration(user)
					}
				}
				.enabled(viewModel.state == .createAccountValid)
				.opacity(viewModel.state == .alreadyHasAccount ? 0 : 1)
				.offset(
					viewModel.state == .alreadyHasAccount ?
					CGSize(width: 0, height: 100) : .zero
				)
				.animation(.easeInOut, value: viewModel.state)
			}
		}
		.navigationTitle("Добро пожаловать!")
		.navigationBarTitleDisplayMode(.large)
		.toolbarBackground(
			Color.white,
			for: .navigationBar
		)
	}
}

struct WelcomeView_Previews: PreviewProvider {
	static var previews: some View {
		WelcomeView()
	}
}

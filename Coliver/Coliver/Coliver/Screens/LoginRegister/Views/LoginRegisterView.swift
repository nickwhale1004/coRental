//
//  LoginRegisterView.swift
//  Coliver
//
//  Created by Никита Шляхов on 15.05.2023.
//

import SwiftUI

struct LoginRegisterView: View {
	
	// MARK: - Properties
	
	@EnvironmentObject private var router: Router
	@StateObject private var viewModel: LoginRegisterViewModel
	
	// MARK: - View
	
    var body: some View {
		ZStack {
			VStack(alignment: .center, spacing: 30) {
				PlainTextField(
					"E-mail",
					text: $viewModel.email,
					isRequired: true
				)
					.invalid($viewModel.isEmailInvalid)
				
				PlainTextField(
					"Пароль",
					text: $viewModel.password,
					isRequired: true,
					isSecure: true
				)
					.invalid($viewModel.isPasswordInvalid)
				
				if case .register = viewModel.mode {
					PlainTextField(
						"Повторите пароль",
						text: $viewModel.passwordRepeat,
						isRequired: true,
						isSecure: true
					)
						.invalid($viewModel.isPasswordRepeatInvalid)
				}
			}
			.frame(maxHeight: .infinity, alignment: .top)
			.padding(.top, 40)
			.padding(.horizontal, 20)
			
			VStack {
				Spacer()
				
				RoundedButton(
					text: viewModel.mode == .login ?
					"Войти": "Зарегистрироваться"
				) { _ in
					viewModel.validate()
					removeFocus()
				}
			}
		}
		.onChange(of: viewModel.state) { newValue in
			switch newValue {
			case .valid:
				viewModel.auth()
			case .authed:
				router.showMain()
			default:
				break
			}
		}
		.navigationTitle(
			viewModel.mode == .login ?
			"Вход": "Регистрация"
		)
		.navigationBarTitleDisplayMode(.large)
		.toolbarBackground(
			Color.white,
			for: .navigationBar
		)
	}
	
	// MARK: - Initialization
	
	init(mode: LoginRegisterViewModel.Mode) {
		_viewModel = StateObject(wrappedValue: LoginRegisterViewModel(mode: mode))
	}
}

struct LoginRegisterView_Previews: PreviewProvider {
    static var previews: some View {
		LoginRegisterView(mode: .login)
    }
}

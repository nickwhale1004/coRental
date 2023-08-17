//
//  ColiverApp.swift
//  Coliver
//
//  Created by Никита Шляхов on 12.05.2023.
//

import SwiftUI
import Combine

@main
struct ColiverApp: App {
	@ObservedObject private var viewModel = ColiverAppViewModel()
	@StateObject private var router = Router()
	
	var body: some Scene {
		WindowGroup {
			if !viewModel.hasAppLoaded {
				SplashView(hasAppLoaded: $viewModel.hasAppLoaded)
					.onReceive(viewModel.tokenPublisher) { isAuthed in
						router.rootView = isAuthed ? .main : .welcome
					}
			} else {
				NavigationStack(path: $router.path) {
					ZStack {
						switch router.rootView {
						case .welcome:
							WelcomeView()
						case .main:
							MainView()
						default:
							Text("Default")
						}
					}
					.environmentObject(router)
					.navigationDestination(for: Route.self) { route in
						ZStack {
							switch route {
							case .welcome:
								WelcomeView()
								
							case .login:
								LoginRegisterView(mode: .login)
								
							case let .register(user):
								LoginRegisterView(mode: .register(user))
								
							case let .completeRegistration(user):
								CompleteRegistrationView(user)
								
							case .main:
								MainView()
							}
						}
						.environmentObject(router)
					}
				}
			}
		}
	}
}

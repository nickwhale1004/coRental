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
			if viewModel.hasAppLoaded {
				NavigationStack(path: $router.path) {
					getView(from: router.rootView)
						.navigationDestination(for: Route.self) { route in
							getView(from: route)
						}
				}
			} else {
				SplashView(hasAppLoaded: $viewModel.hasAppLoaded)
					.onReceive(viewModel.tokenPublisher) { isAuthed in
						router.rootView = isAuthed ? .main : .welcome
					}
			}
		}
	}
	
	@ViewBuilder private func getView(from route: Route) -> some View {
		ZStack {
			switch route {
			case .welcome:
				EditProfileView(mode: .welcome)
				
			case .login:
				LoginRegisterView(mode: .login)
				
			case let .register(user):
				LoginRegisterView(mode: .register(profile: user))
				
			case let .completeRegistration(user):
				SearchSettingsView(mode: .completeRegistration(profile: user))
				
			case .main:
				MainView()
			}
		}
		.environmentObject(router)
	}
}

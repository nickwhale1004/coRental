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
    @ObservedObject private var authManager = AuthManager.shared
	@StateObject private var router = Router()
	
	var body: some Scene {
		WindowGroup {
			if viewModel.hasAppLoaded {
				NavigationStack(path: $router.path) {
					getView(from: router.rootView)
						.navigationDestination(for: Route.self) { route in
							getView(from: route)
						}
                        .onChange(of: authManager.token) { _ in
                            router.rootView = authManager.token != nil ? .main : .welcome
                        }
				}
			} else {
				SplashView(hasAppLoaded: $viewModel.hasAppLoaded)
                    .onChange(of: authManager.token) { _ in
                        router.rootView = authManager.token != nil ? .main : .welcome
                    }
                    .onAppear {
                        viewModel.onAppear()
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
                
            case let .chat(id):
                ChatView(viewModel: ChatViewModel(id: id))
            }
		}
		.environmentObject(router)
	}
}

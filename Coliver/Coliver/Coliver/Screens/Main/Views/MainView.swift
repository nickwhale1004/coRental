//
//  MainView.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import SwiftUI

struct MainView: View {
	@State var userModel = UserModel()
	@StateObject var viewModel = MainViewModel()
	
	var body: some View {
		ZStack {
			switch viewModel.state {
			case .loaded:
				TabView {
					SearchSettingsView($userModel)
						.tabItem {
							Label("Settings", systemImage: "person.2.badge.gearshape")
						}
					SearchView()
						.tabItem {
							Label("Search", systemImage: "list.dash")
						}
					ProfileView($userModel)
						.tabItem {
							Label("Profile", systemImage: "person")
						}
				}
			case .loading:
				Text("Загрузка...")
			case .error:
				RoundedButton(text: "Повторить") { _ in
					viewModel.loadUser()
				}
			}
		}
		.onChange(of: viewModel.state) { state in
			if state == .loaded, let model = viewModel.userModel {
				userModel = model
			}
		}
	}
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

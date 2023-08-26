//
//  MainView.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import SwiftUI

struct MainView: View {
	@StateObject var viewModel = MainViewModel()
	
	var body: some View {
		ZStack {
			switch viewModel.state {
			case .loaded:
				TabView {
					SearchSettingsView(mode: .searchSettings(profile: $viewModel.userModel))
						.tabItem {
							Label("Settings", systemImage: "person.2.badge.gearshape")
						}
					SearchView($viewModel.userModel)
						.tabItem {
							Label("Search", systemImage: "list.dash")
						}
					EditProfileView(mode: .edit(profile: $viewModel.userModel))
						.tabItem {
							Label("Profile", systemImage: "person")
						}
				}
			case .loading:
				Text("Загрузка...")
			case .error:
				RoundedButton(text: "Повторить") { _ in
					viewModel.repeatLoadButtonPressed()
				}
			}
		}
	}
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

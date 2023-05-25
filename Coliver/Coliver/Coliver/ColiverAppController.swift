//
//  ColiverAppViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 23.05.2023.
//

import Foundation

final class ColiverAppViewModel: ObservableObject {
	@Published var hasAppLoaded = false
	@Published var tokenPublisher = AuthManager.shared.checkToken()
}

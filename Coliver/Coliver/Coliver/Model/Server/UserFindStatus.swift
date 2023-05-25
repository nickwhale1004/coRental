//
//  UserStatus.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import Foundation

enum UserFindStatus: Int, CaseIterable, Codable {
	case friend
	case placeAndFriend
}

extension UserFindStatus: TitledObjectProtocol {
	var title: String {
		switch self {
		case .friend:
			return "Ищу с кем жить"
		case .placeAndFriend:
			return "Ищу жилье и с кем жить"
		}
	}
}

//
//  Gender.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import Foundation

enum Gender: Int, Codable, CaseIterable {
	case male
	case female
}

extension Gender: TitledObjectProtocol {
	var title: String {
		switch self {
		case .female:
			return "Женский"
		case .male:
			return "Мужской"
		}
	}
}

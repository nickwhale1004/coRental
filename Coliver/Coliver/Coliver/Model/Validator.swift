//
//  Validator.swift
//  Coliver
//
//  Created by Никита Шляхов on 15.05.2023.
//

import Foundation

final class Validator {
	
	// MARK: - Types
	
	enum Mode: String {
		case email = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
		case password = "^.{6,20}$"
		case namePart = "^[\\p{L}]{1,20}$"
		case age = "[0-9]{1,3}$"
	}
	
	// MARK: - Properties
	
	private let mode: Mode
	
	// MARK: - Initialzation
	
	init(mode: Mode) {
		self.mode = mode
	}
	
	// MARK: - Methods
	
	func isValid(_ input: String) -> Bool {
		return input.range(of: mode.rawValue, options: .regularExpression) != nil
	}
}

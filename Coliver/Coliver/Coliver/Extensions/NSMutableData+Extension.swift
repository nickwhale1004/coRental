//
//  NSMutableData+Extension.swift
//  Coliver
//
//  Created by Никита Шляхов on 23.05.2023.
//

import Foundation

extension NSMutableData {
	func appendString(_ string: String) {
		if let data = string.data(using: .utf8) {
			append(data)
		}
	}
}

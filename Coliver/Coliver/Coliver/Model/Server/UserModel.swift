//
//  UserModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import Foundation

struct UserModel: Codable, Hashable {
	var firstName: String
	var lastName: String
	var thirdName: String?
	var age: Int
	var gender: Gender
	var about: String?
	
	var house: HouseModel?
	var search: SearchModel?
}

extension UserModel {
	init() {
		firstName = ""
		lastName = ""
		age = 0
		gender = .male
	}
}

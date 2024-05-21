//
//  UserModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import Foundation

struct UserModel: Codable, Hashable {
    var id: Int? = nil
	var firstName: String = ""
	var lastName: String = ""
	var thirdName: String?
	var age: Int = 0
	var gender: Gender = .male
    var country: String = ""
	var about: String?
	
	var house: HouseModel?
	var search: SearchModel?
}

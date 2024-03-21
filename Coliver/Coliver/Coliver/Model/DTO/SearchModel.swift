//
//  SearchModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import Foundation

struct SearchModel: Codable, Hashable {
	var type: UserFindStatus
	
	var userAgeFrom: Int?
	var userAgeTo: Int?
	var userGender: Gender?
	
	var housePriceFrom: Int?
	var housePriceTo: Int?
}

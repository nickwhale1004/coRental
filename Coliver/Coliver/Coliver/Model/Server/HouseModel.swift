//
//  HouseModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import Foundation

struct HouseModel: Codable, Hashable {
	var address: String
	var price: Int
	var imageURL: String?
}

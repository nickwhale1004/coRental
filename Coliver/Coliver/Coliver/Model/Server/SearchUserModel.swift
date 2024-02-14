//
//  SearchUserModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 13.02.2024.
//

import Foundation

struct SearchUserModel: Decodable, Hashable {
    var id: Int
    var firstName: String
    var lastName: String
    var thirdName: String?
    var age: Int
    var gender: Gender
    var about: String?
    var isLiked: Bool
    
    var house: HouseModel?
    var search: SearchModel?
}

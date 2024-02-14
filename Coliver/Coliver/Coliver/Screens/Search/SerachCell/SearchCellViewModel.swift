//
//  SearchCellViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import Foundation

final class SearchCellViewModel: ObservableObject {
    let id: Int
	
	@Published var name: String
	@Published var age: Int
	@Published var about: String
	
	@Published var imageUrl: String?
	@Published var address: String?
	@Published var price: Int?
    
    @Published var isLiked: Bool
	
	init(_ model: SearchUserModel) {
        id = model.id
		name = model.firstName + " " + model.lastName
		age = model.age
		about = model.about ?? ""
		
		address = model.house?.address
		price = model.house?.price
		
		imageUrl = model.house?.imageUrl
        isLiked = model.isLiked
	}
}

extension SearchCellViewModel: Hashable {
    static func == (lhs: SearchCellViewModel, rhs: SearchCellViewModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.age == rhs.age &&
        lhs.about == rhs.about &&
        lhs.imageUrl == rhs.imageUrl &&
        lhs.address == rhs.address &&
        lhs.price == rhs.price &&
        lhs.isLiked == rhs.isLiked
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(age)
        hasher.combine(about)
        hasher.combine(imageUrl)
        hasher.combine(address)
        hasher.combine(price)
        hasher.combine(isLiked)
    }
}

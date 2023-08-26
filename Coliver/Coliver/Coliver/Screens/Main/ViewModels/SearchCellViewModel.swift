//
//  SearchCellViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import Foundation

final class SearchCellViewModel: ObservableObject, Identifiable {
	let id = UUID()
	
	@Published var name: String
	@Published var age: Int
	@Published var about: String
	
	@Published var imageURL: String?
	@Published var address: String?
	@Published var price: Int?
	
	init(_ model: UserModel) {
		name = model.firstName + " " + model.lastName
		age = model.age
		about = model.about ?? ""
		
		address = model.house?.address
		price = model.house?.price
		
		imageURL = model.house?.imageURL
	}
}

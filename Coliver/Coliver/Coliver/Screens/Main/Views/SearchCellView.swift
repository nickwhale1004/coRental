//
//  SearchCellView.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import SwiftUI

struct SearchCellView: View {
	@StateObject var viewModel: SearchCellViewModel
	
	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 10) {
				Text(viewModel.name)
					.bold()
				Text("\(viewModel.age) лет")
				Text("\(viewModel.about)")
					.italic()
			}
			.padding(.leading, 10)
			.padding(.vertical, 20)
			.frame(maxWidth: .infinity, alignment: .leading)
			
			if viewModel.address != nil {
				VStack(alignment: .center, spacing: 10) {
					AsyncCachedImage(url: viewModel.imageURL) { image in
						image
							.resizable()
							.scaledToFit()
					} placeholder: {
						Image(systemName: "house.fill")
							.resizable()
							.scaledToFit()
							.padding(10)
					}
					Text(viewModel.address ?? "")
						.padding(.horizontal, 5)
					Text("\(viewModel.price ?? 0) руб")
						.padding(.bottom, 10)
				}
				.frame(maxWidth: 200)
				.background(Color(.secondaryLabel.withAlphaComponent(0.2)))
				.cornerRadius(10)
				.padding(.trailing, 10)
				.padding(.vertical, 20)
			}
		}
		.background(Color(.secondarySystemBackground))
		.cornerRadius(10)
		.padding(.horizontal, 20)
		.frame(maxHeight: 500)
    }
	
	init(_ viewModel: SearchCellViewModel) {
		_viewModel = StateObject(wrappedValue: viewModel)
	}
}

struct SearchCellView_Previews: PreviewProvider {
    static var previews: some View {
		let house = HouseModel(address: "ул. Черепахина", price: 22000)
		let model = UserModel(firstName: "Nikita", lastName: "Shlyakhov", age: 12, gender: .male, about: "Программист и просто хороший праень", house: house)
        SearchCellView(SearchCellViewModel(model))
    }
}

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
        HStack(alignment: .top) {
			VStack(alignment: .leading, spacing: 4) {
				Text(viewModel.name)
					.bold()
                
				Text("\(viewModel.age) лет")
                    .font(.system(size: 14))
                    .padding(.bottom, 4)
                
                if viewModel.address != nil {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 1)
                        .padding(.bottom, 4)
                    
                    Text("\(viewModel.price ?? 0) руб")
                        .bold()
                    
                    Text("\(viewModel.address ?? "")")
                        .font(.system(size: 14))
                        .italic()
                } else {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 1)
                        .padding(.bottom, 4)
                    
                    Text("Ищет жилье")
                        .font(.system(size: 14))
                        .italic()
                }
			}
			
			if viewModel.address != nil {
				VStack(spacing: 0) {
                    Spacer()
                    
					AsyncCachedImage(url: viewModel.imageUrl) { image in
						image
							.resizable()
							.scaledToFit()
					} placeholder: {
						Image(systemName: "house.fill")
							.resizable()
							.scaledToFit()
					}
                    .cornerRadius(10)
                    .padding(.leading, 10)
                    
                    Spacer()
				}
				.frame(maxWidth: 180)
			}
		}
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 5)
                .frame(maxWidth: .infinity, maxHeight: 500)
        )
    }
}

struct SearchCellView_Previews: PreviewProvider {
    static var previews: some View {
		let house = HouseModel(address: "ул. Черепахина 128", price: 22000)
		let model = UserModel(firstName: "Nikita", lastName: "Shlyakhov", age: 12, gender: .male, about: "Программист и просто хороший праень", house: house)
        SearchCellView(viewModel: SearchCellViewModel(model))
    }
}

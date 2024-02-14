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
        ZStack(alignment: .bottomTrailing) {
            mainContent
            heartIcon
        }
    }
    
    private var mainContent: some View {
        HStack(alignment: .top) {
            userInfo
            if viewModel.address != nil {
                imageView
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 5)
        )
    }
    
    private var userInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.name)
                .bold()
            
            Text("\(viewModel.age) лет")
                .font(.system(size: 14))
                .padding(.bottom, 4)
            
            if viewModel.address != nil {
                addressInfo
            } else {
                Text("Ищет жилье")
                    .font(.system(size: 14))
                    .italic()
            }
        }
    }
    
    private var addressInfo: some View {
        VStack(alignment: .leading) {
            line
            
            Text("\(viewModel.price ?? 0) руб")
                .bold()
            
            Text("\(viewModel.address ?? "")")
                .font(.system(size: 14))
                .italic()
        }
    }
    
    private var imageView: some View {
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
                    .frame(width: 100, height: 100)
            }
            .cornerRadius(10)
            .padding(.leading, 10)
            Spacer()
        }
        .frame(maxWidth: 180, maxHeight: 180)
    }
    
    private var heartIcon: some View {
        Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
            .resizable()
            .frame(width: 30, height: 28)
            .foregroundColor(viewModel.isLiked ? .red : .gray)
            .padding([.bottom, .trailing], 16)
    }
    
    private var line: some View {
        Rectangle()
            .fill(Color.gray)
            .frame(height: 1)
            .padding(.bottom, 4)
    }
}

struct SearchCellView_Previews: PreviewProvider {
    static var previews: some View {
        let model = SearchUserModel(
            id: 0,
            firstName: "Nikita",
            lastName: "Shlyakhov",
            age: 12,
            gender: .male,
            about: "Программист и просто хороший праень",
            isLiked: true,
            house: HouseModel(address: "ул. Черепахина 128", price: 22000)
        )
        let model2 = SearchUserModel(
            id: 0,
            firstName: "Nikita",
            lastName: "Shlyakhov",
            age: 12,
            gender: .male,
            about: "Программист и просто хороший праень",
            isLiked: true
        )
        SearchCellView(viewModel: SearchCellViewModel(model))
        SearchCellView(viewModel: SearchCellViewModel(model2))
    }
}

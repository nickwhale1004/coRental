//
//  ChatListCell.swift
//  Coliver
//
//  Created by Никита Шляхов on 27.08.2023.
//

import SwiftUI

struct ChatListCell: View {
	
	// MARK: - Properties
	
	@ObservedObject var viewModel: ChatListCellViewModel
    let action: (Int) -> Void
	
	// MARK: - Views
	
    var body: some View {
        Button(action: {
            action(viewModel.id)
        }, label: {
            VStack(spacing: 5) {
                Rectangle()
                    .fill(Color(.lightGray))
                    .frame(height: 1)
                    .padding(.bottom, 7)
                
                HStack {
                    Text(viewModel.name)
                        .bold()
                        .foregroundStyle(Color.black)
                    Spacer()
                    Text(viewModel.date)
                        .foregroundColor(Color(.darkGray))
                }
                .padding(.horizontal)
                
                HStack {
                    Text(viewModel.text)
                        .foregroundColor(Color(.darkGray))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 7)
                
                Rectangle()
                    .fill(Color(.lightGray))
                    .frame(height: 1)
            }
        })
    }
}

struct ChatListCell_Previews: PreviewProvider {
    static var previews: some View {
        ChatListCell(viewModel: ChatListCellViewModel(model: ChatModel(id: 0, userName: "Петя Петров", lastMessage: "Привет как дела?", timestamp: Date()))) { _ in }
    }
}

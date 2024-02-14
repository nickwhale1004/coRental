//
//  ChatListView.swift
//  Coliver
//
//  Created by Никита Шляхов on 26.08.2023.
//

import SwiftUI

struct ChatListView: View {
	
	// MARK: - Properties
	
    @EnvironmentObject private var router: Router
	@ObservedObject private var viewModel = ChatListViewModel()
	
	// MARK: - Views
	
    var body: some View {
        ZStack {
            ScrollView {
                Text("Чаты")
                    .font(.largeTitle)
                    .bold()
                    .padding(.vertical, 16)
                
                LazyVStack(spacing: -1) {
                    ForEach(viewModel.cellViewModels, id: \.id) { cellViewModel in
                        ChatListCell(viewModel: cellViewModel) { id in
                            router.showChat(id: id)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .onAppear {
                viewModel.onAppear()
            }
        }
    }
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}

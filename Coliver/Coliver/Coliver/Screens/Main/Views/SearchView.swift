//
//  SearchView.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import SwiftUI

struct SearchView: View {
	@StateObject private var viewModel: SearchViewModel
	
	var body: some View {
		ZStack {
			if viewModel.state == .loaded {
				ScrollView {
					LazyVStack(spacing: 10) {
						ForEach(viewModel.cellViewModels, id: \.id) { cellViewModel in
							SearchCellView(cellViewModel)
						}
					}
				}
			} else {
				Text(viewModel.text)
			}
		}
		.onAppear(perform: {
			viewModel.search()
		})
	}
	
	init(_ model: Binding<UserModel?>) {
		_viewModel = StateObject(wrappedValue: SearchViewModel(userBinding: model))
	}
}

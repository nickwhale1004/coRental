//
//  SearchView.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import SwiftUI

struct SearchView: View {
	@StateObject private var viewModel = SearchViewModel()
	
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
}

struct SearchView_Previews: PreviewProvider {
	static var previews: some View {
		SearchView()
	}
}

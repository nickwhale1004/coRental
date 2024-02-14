//
//  SearchView.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import SwiftUI

struct SearchView: View {
    @State private var showBottomSheet = false
	@StateObject private var viewModel: SearchViewModel
    @State private var tmpViewModel: SearchCellViewModel?
	
	var body: some View {
		ZStack {
			if viewModel.state == .loaded {
				ScrollView {
                    Text("Люди")
                        .font(.largeTitle)
                        .bold()
                        .padding(.vertical, 16)
                    
					LazyVStack(spacing: 16) {
						ForEach(viewModel.cellViewModels, id: \.self) { cellViewModel in
                            SearchCellView(viewModel: cellViewModel)
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    tmpViewModel = cellViewModel
                                    showBottomSheet.toggle()
                                }
						}
					}
				}
			} else {
				Text(viewModel.text)
			}
            
            BottomSheetView(isPresented: $showBottomSheet) {
                VStack(alignment: .leading, spacing: -1) {
                    Text("Выберите действие")
                        .font(.title)
                        .bold()
                        .foregroundStyle(Color.black)
                        .padding(.bottom, 17)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    button(text: "Написать сообщение") { cellViewModel in
                        viewModel.writeMessageTapped(cellViewModel)
                    }
                    button(text: tmpViewModel?.isLiked == true ? "Мне не нравится" : "Мне нравится") { cellViewModel in
                        if tmpViewModel?.isLiked == true {
                            viewModel.unlikeTapped(cellViewModel)
                        } else {
                            viewModel.likeTapped(cellViewModel)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
		}
        .onAppear {
			viewModel.onAppear()
		}
	}
    
    private func button(
        text: String,
        _ action: @escaping (SearchCellViewModel) -> Void
    ) -> some View {
        Button {
            withAnimation {
                guard let tmpViewModel else { return }
                showBottomSheet = false
                action(tmpViewModel)
            }
        } label: {
            VStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 1)
                
                Text(text)
                    .foregroundStyle(Color.black)
                
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 1)
            }
            .padding(.horizontal, 16)
        }
    }
	
	init(_ model: Binding<UserModel?>) {
		_viewModel = StateObject(wrappedValue: SearchViewModel(userBinding: model))
	}
}

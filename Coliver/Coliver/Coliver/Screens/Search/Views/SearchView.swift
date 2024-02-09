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
						ForEach(viewModel.cellViewModels, id: \.id) { cellViewModel in
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
                VStack(alignment: .leading) {
                    Text("Выберите действие")
                        .font(.title)
                        .bold()
                        .foregroundStyle(Color.black)
                        .padding(.bottom, 6)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    Button {
                        withAnimation {
                            guard let tmpViewModel else { return }
                            showBottomSheet = false
                            viewModel.cellTapped(tmpViewModel)
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray)
                                .frame(height: 1)
                            
                            Text("Написать сообщение")
                                .foregroundStyle(Color.black)
                            
                            Rectangle()
                                .fill(Color.gray)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
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

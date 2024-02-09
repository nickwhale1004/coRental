//
//  ChatView.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.12.2023.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    if viewModel.messages.isEmpty {
                        Text("Пока что здесь ничего нет")
                            .foregroundStyle(Color.gray)
                    }
                    ForEach(viewModel.messages, id: \.id) { message in
                        MessageCell(viewModel: message)
                            .padding(.bottom, 5)
                    }
                    lastRow
                        .onAppear {
                            viewModel.onLastMessageAppear()
                        }
                }
                .padding(.horizontal, 16)
            }
            inputView
        }
        .onAppear {
            viewModel.onAppear()
        }
        .navigationTitle("Чат")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var inputView: some View {
        HStack(spacing: 15) {
            TextField("Введите сообщение", text: $viewModel.text)
                .frame(height: 30)
                .padding(.horizontal, 5)
                .background(Color.white)
                .cornerRadius(5.0)
                .padding(.top, 16)
            
            Button(action: {
                viewModel.sendButtonTapped()
            }, label: {
                Image(systemName: "paperplane")
                    .resizable()
                    .padding(.all, 10)
                    .background(
                        Circle()
                            .fill(Color.black)
                    )
                    .foregroundStyle(Color.white)
                    .frame(width: 40, height: 40)
            })
            .padding(.top, 16)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
            Color(uiColor: UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1))
        )
    }
    
    private var lastRow: some View {
        Group {
            switch viewModel.paginationState {
            case .isLoading:
                ProgressView()
            case .finished, .idle:
                EmptyView()
            case .error:
                Text("Ошибка!")
            }
        }
    }
}

#Preview {
    let viewModel = ChatViewModel(id: 0)
    viewModel.messages = [
        MessageCellViewModel(model: .init(id: 0, userName: "AAA", messageText: "aaa", timestamp: Date())),
        MessageCellViewModel(model: .init(id: 1, userName: "BBB", messageText: "bbb", timestamp: Date()))
    ]
    return ChatView(viewModel: viewModel)
}

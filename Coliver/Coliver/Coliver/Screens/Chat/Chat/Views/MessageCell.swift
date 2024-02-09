//
//  MessageCell.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.12.2023.
//

import SwiftUI

struct MessageCell: View {
    @ObservedObject var viewModel: MessageCellViewModel
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(viewModel.userName)
                    .bold()
                Spacer()
                Text(viewModel.date)
                    .foregroundColor(Color(.darkGray))
            }
            HStack {
                Text(viewModel.messageText)
                    .foregroundColor(Color(.darkGray))
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    MessageCell(viewModel: MessageCellViewModel(model: MessageModel(id: 0, userName: "Дима Петров", messageText: "Привет! Как будут твоии дела если это сообщение станет реально очень большим и перестанет помещаться в одну строчку и тогда начнет расти вниз \n\nна несколько строк сразу", timestamp: Date())))
}

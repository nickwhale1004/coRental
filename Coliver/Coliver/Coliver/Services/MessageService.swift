//
//  MessageService.swift
//  Coliver
//
//  Created by Никита Шляхов on 16.12.2023.
//

import Foundation
import Combine
import SocketIO

protocol MessageServiceProtocol {
    var messageStream: AsyncStream<MessageModel> { get }
    
    func connect()
    func disconnect()
    func sendMessage(chatId: Int, text: String)
}

final class MessageService: MessageServiceProtocol {
    lazy var messageStream: AsyncStream<MessageModel> = {
        AsyncStream { (continuation: AsyncStream<MessageModel>.Continuation) -> Void in
            self.continuation = continuation
        }
    }()
    private var continuation: AsyncStream<MessageModel>.Continuation?
    
    private var socket: SocketIOClient
    
    private let manager: SocketManager
    private let authManager: AuthManagerProtocol
    
    private lazy var decoder = JSONDecoder.smartDecoder
    
    // MARK: - Initialization
    
    init(authManager: AuthManagerProtocol = AuthManager.shared) {
        self.authManager = authManager
        
        self.manager = SocketManager(socketURL: URL(string: "http://127.0.0.1:3000/")!, config: [.log(true)])
        self.socket = manager.defaultSocket
    }

    func connect() {
        guard let token = authManager.token else { return }
        socket.on(clientEvent: .connect) { _, _ in
            print("connected!")
        }
        socket.on(clientEvent: .error) { error1, error2 in
            print(error1)
            print(error2)
        }
        receiveMessages()
        socket.connect(withPayload: ["token": token])
    }

    func disconnect() {
        socket.disconnect()
    }

    func sendMessage(chatId: Int, text: String) {
        let message: [String: Any] = [
            "token": authManager.token ?? "",
            "chat_id": chatId,
            "text": text
        ]
        socket.emit("send_message", message)
    }
    
    private func receiveMessages() {
        socket.on("receive_message") { [weak self] data, ack in
            guard let self, let jsonData = try? JSONSerialization.data(withJSONObject: data.first as Any) else { return }
            do {
                let message = try decoder.decode(MessageModel.self, from: jsonData)
                continuation?.yield(message)
            } catch {
                print(error)
            }
        }
    }
}

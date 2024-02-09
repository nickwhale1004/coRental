//
//  NetworkService.swift
//  Coliver
//
//  Created by Никита Шляхов on 07.02.2024.
//

import Foundation

protocol NetworkServiceProtocol {
    func request<T: Decodable>(url: String, body: Encodable, http: HttpRequest) async throws -> T
    func request<T: Decodable>(url: String, body: Encodable) async throws -> T
    
    func request<T: Decodable>(from request: URLRequest) async throws -> T
    func request<T: Decodable>(from url: String) async throws -> T
    
    func request(url: String, body: Encodable, http: HttpRequest) async throws
    func request(url: String, body: Encodable) async throws
}

extension NetworkServiceProtocol {
    func request<T: Decodable>(url: String, body: Encodable) async throws -> T {
        try await request(url: url, body: body, http: .post)
    }
    func request(url: String, body: Encodable) async throws {
        try await request(url: url, body: body, http: .post)
    }
}
    
enum HttpRequest: String {
    case get = "GET"
    case post = "POST"
}

enum NetworkError: Error {
    case wrongURL
    case badStatusCode(Int)
    case brokenImage
}

final class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Properties
    
    private let session: URLSession
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            guard let date = ISO8601DateFormatter().date(from: dateStr) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
            }
            return date
        }
        return decoder
    }()
    
    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    // MARK: - Initialization
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Methods
    
    func request<T: Decodable>(url: String, body: Encodable, http: HttpRequest = .post) async throws -> T {
        print("Отправка запроса: \(url)")
        guard
            let url = URL(string: url)
        else {
            throw NetworkError.wrongURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = http.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try handleResponse(data: data, response: response)
        
        return try decoder.decode(T.self, from: data)
    }
    
    func request<T: Decodable>(from request: URLRequest) async throws -> T {
        print("Отправка запроса: \(request.url?.absoluteString ?? "")")
        
        let (data, response) = try await session.data(for: request)
        try handleResponse(data: data, response: response)
        
        return try decoder.decode(T.self, from: data)
    }
    
    func request<T: Decodable>(from url: String) async throws -> T {
        print("Отправка запроса: \(url)")
        guard
            let url = URL(string: url)
        else {
            throw NetworkError.wrongURL
        }
        let (data, response) = try await session.data(from: url)
        try handleResponse(data: data, response: response)
        
        if T.self == Data.self {
            return data as! T
        }
        return try decoder.decode(T.self, from: data)
    }
    
    func request(url: String, body: Encodable, http: HttpRequest = .post) async throws {
        print("Отправка запроса: \(url)")
        guard
            let url = URL(string: url)
        else {
            throw NetworkError.wrongURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = http.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try handleResponse(data: data, response: response)
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws {
        let stringResponse = String(data: data, encoding: .utf8) ?? "unconvertable to string data (may be image or file)"
        if let httpResponse = response as? HTTPURLResponse {
            print("Получен ответ: \nStatus code - \(httpResponse.statusCode) \n \(stringResponse)\n")
            if httpResponse.statusCode != 200 {
                throw NetworkError.badStatusCode(httpResponse.statusCode)
            }
        }
    }
}

//
//  ApiService+Image.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import Foundation
import Combine
import UIKit

protocol ImageServiceProtocol {
	func uploadImage(_ imageData: Data) async throws -> String
	func downloadImage(_ url: String) async throws -> UIImage
}

final class ImageService: ImageServiceProtocol {
    
    // MARK: - Types
    
    struct ImageResponse: Codable {
        let url: String
    }
	
	// MARK: - Properties
	
	private let url = "http://127.0.0.1:5000/"
	private let networkService: NetworkServiceProtocol
	
    // MARK: - Initialization
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
	
	// MARK: - Methods
	
    func uploadImage(_ imageData: Data) async throws -> String {
		guard
			let url = URL(string: url + "upload")
		else {
            throw NetworkError.wrongURL
		}
		
		var request = URLRequest(url: url)
        request.httpMethod = HttpRequest.post.rawValue
		
		let boundary = UUID().uuidString
		let contentType = "multipart/form-data; boundary=\(boundary)"
		request.setValue(contentType, forHTTPHeaderField: "Content-Type")
		
		let body = NSMutableData()
		body.appendString("--\(boundary)\r\n")
		body.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n")
		body.appendString("Content-Type: image/jpeg\r\n\r\n")
		body.append(imageData)
		body.appendString("\r\n")
		body.appendString("--\(boundary)--\r\n")
		
		request.httpBody = body as Data
        
        let response: ImageResponse = try await networkService.request(from: request)
        return response.url
	}
	
	func downloadImage(_ url: String) async throws -> UIImage {
        let response: Data = try await networkService.request(from: url)
        guard let image = UIImage(data: response) else { throw NetworkError.brokenImage }
        return image
	}
}

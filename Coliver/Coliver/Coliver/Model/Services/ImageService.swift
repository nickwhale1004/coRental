//
//  ApiService+Image.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.05.2023.
//

import Foundation
import Combine

protocol ImageServiceProtocol {
	func uploadImage(_ imageData: Data) -> AnyPublisher<String, Error>
	func downloadImage(_ url: String) -> AnyPublisher<Data, Error>
}

final class ImageService: ImageServiceProtocol {
	
	// MARK: - Properties
	
	let url = "http://127.0.0.1:5000/"
	
	// MARK: - Methods
	
	func uploadImage(_ imageData: Data) -> AnyPublisher<String, Error> {
		guard
			let url = URL(string: url + "upload")
		else {
			return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		
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
		
		return URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response -> String in
				guard
					let httpResponse = response as? HTTPURLResponse,
					httpResponse.statusCode == 200,
					let json = try? JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any>,
					let imageUrl = json["url"] as? String
				else {
					throw URLError(.badServerResponse)
				}
				return imageUrl
			}
			.eraseToAnyPublisher()
	}
	
	func downloadImage(_ url: String) -> AnyPublisher<Data, Error> {
		guard
			let url = URL(string: url)
		else {
			return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		
		return URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response -> Data in
				guard
					let httpResponse = response as? HTTPURLResponse,
					httpResponse.statusCode == 200
				else {
					throw URLError(.badServerResponse)
				}
				return data
			}
			.eraseToAnyPublisher()
	}
}

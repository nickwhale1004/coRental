//
//  CacheManager.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.08.2023.
//

import UIKit

protocol CacheManagerProtocol {
	subscript(_ path: String) -> UIImage? { get set }
}

final class CacheManager: CacheManagerProtocol {
	
	// MARK: - Properties
	
	private let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	
	// MARK: - Subscript
	
	subscript(_ path: String) -> UIImage? {
		get {
			let formatted = path
				.replacingOccurrences(of: "/", with: ".")
				.replacingOccurrences(of: ":", with: ".")
			
			let fileURL = url.appendingPathComponent(formatted)
			if let data = try? Data(contentsOf: fileURL) {
				return UIImage(data: data)
			}
			return nil
		}
		set {
			DispatchQueue.global().async {
				let formatted = path
					.replacingOccurrences(of: "/", with: ".")
					.replacingOccurrences(of: ":", with: ".")
				
				let fileURL = self.url.appendingPathComponent(formatted)
				if let imageData = newValue?.jpegData(compressionQuality: 1.0) {
					try? imageData.write(to: fileURL, options: .atomic)
				}
			}
		}
	}
}

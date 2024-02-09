//
//  AsyncCachedImageViewModel.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.08.2023.
//

import Combine
import UIKit

final class AsyncCachedImageViewModel: ObservableObject {
	
	// MARK: - Properties
	
	@Published var image: UIImage?
	
	private let url: String?
	
	private let imageService: ImageServiceProtocol
	private var cacheManager: CacheManagerProtocol
	
	private var cancellables = [AnyCancellable]()
	
	// MARK: - Initialization
	
	init(
		url: String?,
		imageService: ImageServiceProtocol = ImageService(),
		cacheManager: CacheManagerProtocol = CacheManager()
	) {
		self.url = url
		self.imageService = imageService
		self.cacheManager = cacheManager
		
		getImage()
	}
	
	// MARK: - Methods
	
	private func getImage() {
		guard let url else { return }
		
		if let cacheImage = cacheManager[url] {
			image = cacheImage
		}
        Task { @MainActor in
            do {
                cacheManager[url] = try await imageService.downloadImage(url)
            } catch {
                image = nil
            }
        }
	}
}

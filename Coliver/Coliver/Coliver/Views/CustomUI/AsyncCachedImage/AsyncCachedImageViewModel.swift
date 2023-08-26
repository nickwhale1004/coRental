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
		imageService.downloadImage(url)
			.receive(on: DispatchQueue.main)
			.sink { [weak self] completion in
				guard let self, case .failure = completion else { return }
				image = nil
				
			} receiveValue: { [weak self] data in
				guard let self else { return }
				
				image = UIImage(data: data)
				cacheManager[url] = image
			}
			.store(in: &cancellables)
	}
}

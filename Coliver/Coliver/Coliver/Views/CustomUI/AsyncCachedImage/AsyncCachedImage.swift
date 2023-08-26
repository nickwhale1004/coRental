//
//  AsyncCachedImage.swift
//  Coliver
//
//  Created by Никита Шляхов on 24.08.2023.
//

import SwiftUI

struct AsyncCachedImage<I: View, P: View>: View {
	
	// MARK: - Properties
	
	@StateObject private var viewModel: AsyncCachedImageViewModel
	
	@ViewBuilder private let content: (Image) -> I
	@ViewBuilder private let placeholder: () -> P
	
	// MARK: - View
	
    var body: some View {
		if let image = viewModel.image {
			content(Image(uiImage: image))
		} else {
			placeholder()
		}
    }
	
	// MARK: - Initialization
	
	init(
		url: String?,
		@ViewBuilder content: @escaping (Image) -> I,
		@ViewBuilder placeholder: @escaping () -> P
	) {
		self.content = content
		self.placeholder = placeholder
		
		_viewModel = StateObject(wrappedValue: AsyncCachedImageViewModel(url: url))
	}
}

struct AsyncCachedImage_Previews: PreviewProvider {
    static var previews: some View {
		AsyncCachedImage(url: "") { image in
			image
		} placeholder: {
			Image("")
		}
    }
}

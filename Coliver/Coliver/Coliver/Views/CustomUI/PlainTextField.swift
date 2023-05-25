//
//  PlainTextField.swift
//  Coliver
//
//  Created by Никита Шляхов on 12.05.2023.
//

import SwiftUI

struct PlainTextField: View {
	
	// MARK: - Types
	
	enum Size {
		case usuall
		case extended
		
		var height: CGFloat? {
			switch(self) {
			case .usuall:
				return nil
			case .extended:
				return 150
			}
		}
	}
	
	// MARK: - Properties
	
	private var placeholder = ""
	private var size = Size.extended
	private var keyboardType = UIKeyboardType.default
	private let isRequired: Bool
	private let isSecure: Bool
	
	// MARK: - States
	
	@Binding private var text: String
	@FocusState private var isTextFieldFocused: Bool
	@Binding private var isInvalid: Bool
	
	// MARK: - View
	
	var body: some View {
		VStack(spacing: 0) {
			(
				isSecure ?
				AnyView(SecureField(placeholder, text: $text))
				: AnyView(TextField(placeholder, text: $text))
			)
			.overlay(alignment: .trailing) {
				if !text.isEmpty && isTextFieldFocused {
					Button(action: {
						text = ""
					}) {
						Image(systemName: "xmark")
							.foregroundColor(.secondary)
					}
					.padding(.trailing, 5)
				}
			}
			.foregroundColor(isInvalid ? .red : .black)
			.keyboardType(keyboardType)
			.frame(width: nil, height: size.height, alignment: .top)
			.focused($isTextFieldFocused)
			.bold(text.isEmpty && isRequired)
			.onChange(of: text) { newValue in
				isInvalid = false
			}
			.onChange(of: isTextFieldFocused) { newValue in
				isInvalid = isInvalid && !isTextFieldFocused
			}
			
			RoundedRectangle(cornerRadius: 2)
				.frame(height: 2)
				.foregroundColor(isInvalid ? .red : .black)
		}
	}
	
	// MARK: - Initialization
	
	init(
		_ placeholder: String,
		text: Binding<String>,
		size: Size = .usuall,
		isRequired: Bool = false,
		isSecure: Bool = false
	) {
		self.placeholder = placeholder + (isRequired ? "*" : "")
		self.size = size
		self.isRequired = isRequired
		self.isSecure = isSecure
		
		_text = text
		_isInvalid = Binding<Bool>.constant(false)
	}
	
	init(
		_ placeholder: String,
		text: String?,
		size: Size = .usuall,
		isRequired: Bool = false,
		isSecure: Bool = false
	) {
		self.placeholder = placeholder + (isRequired ? "*" : "")
		self.size = size
		self.isRequired = isRequired
		self.isSecure = isSecure
		
		_text = Binding<String>.constant(text ?? "")
		_isInvalid = Binding<Bool>.constant(false)
	}
	
	init(
		_ placeholder: String,
		value: Binding<Int?>,
		isRequired: Bool = false,
		isSecure: Bool = false
	) {
		let binding = Binding<String>(
			get: { value.wrappedValue?.description ?? "" },
			set: { newValue in
				value.wrappedValue = Int(newValue)
			}
		)
		self.init(
			placeholder,
			text: binding,
			size: .usuall,
			isRequired: isRequired,
			isSecure: isSecure
		)
		keyboardType = .decimalPad
	}
	
	// MARK: - Methods
	
	func invalid(_ value: Binding<Bool>) -> some View {
		var view = self
		view._isInvalid = value
		return view
	}
}

struct PlainTextField_Previews: PreviewProvider {
	static var previews: some View {
		PlainTextField("name", text: Binding.constant("here"), size: .usuall)
		PlainTextField("name2", text: Binding.constant("here2"), size: .extended)
	}
}

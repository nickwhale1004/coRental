//
//  PickerTextField.swift
//  Coliver
//
//  Created by Никита Шляхов on 13.05.2023.
//

import SwiftUI

struct PickerTextField<Tag: TitledProtocol>: View {
	
	// MARK: - Properties
	
	private var placeholder: String
	private var items: [Tag]
	private let isRequired: Bool
	
	// MARK: - States
	
	@Binding private var selection: Tag?
	@State private var isFocused = false
	
	// MARK: - View
	
	var body: some View {
		VStack(spacing: 10) {
			PlainTextField(
				placeholder,
				text: selection?.title,
				isRequired: isRequired
			)
				.disabled(true)
				.onTapGesture {
					withAnimation(.easeInOut(duration: 0.5)) {
						isFocused = true
					}
				}
			
			if isFocused {
				Picker("", selection: $selection) {
					ForEach(items, id: \.self) { item in
						Text(item.title)
							.tag(item as Tag?)
					}
				}
				.pickerStyle(.segmented)
				.colorMultiply(.blue)
				.onChange(of: selection) { value in
					withAnimation(.easeInOut(duration: 0.5).delay(2)) {
						isFocused = false
					}
				}
			}
		}
	}
	
	// MARK: - Initialization
	
	init(_ placeholder: String, items: [Tag], selection: Binding<Tag?>, isRequired: Bool = false) {
		self.placeholder = placeholder
		self.items = items
		self.isRequired = isRequired
		self._selection = selection
	}
}

struct PickerTextField_Previews: PreviewProvider {
	static var previews: some View {
		PickerTextField("Пол", items: Array(Gender.allCases), selection: Binding<Gender?>.constant(.male))
	}
}

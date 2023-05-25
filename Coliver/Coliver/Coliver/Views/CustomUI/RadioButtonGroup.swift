//
//  RadioButtonView.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import SwiftUI

struct RadioButtonGroup<Tag: TitledObjectProtocol>: View {
	
	// MARK: Types
	
	enum Orientation {
		case horizonal, vertical
	}
	
	// MARK: Properties
	
	@Binding var selection: Tag
	let orientation: Orientation
	let items: [Tag]
	
	// MARK: - View
	
	var body: some View {
		(
			(orientation == .horizonal)
			? AnyLayout(HStackLayout(alignment: .top))
			: AnyLayout(VStackLayout(alignment: .leading))
		) {
			ForEach(items, id: \.self) { item in
				RadioButton(tag: item, selection: $selection)
			}
		}
	}
}

struct RadioButtonGroup_Previews: PreviewProvider {
	static var previews: some View {
		RadioButtonGroup(selection: Binding<UserFindStatus>.constant(.friend), orientation: .vertical, items: Array(UserFindStatus.allCases))
	}
}

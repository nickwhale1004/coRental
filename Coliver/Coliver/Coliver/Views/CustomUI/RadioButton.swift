//
//  RadioButton.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

import SwiftUI

struct RadioButton<Tag: TitledObjectProtocol>: View {
	let tag: Tag
	@Binding var selection: Tag
	
	var body: some View {
		Button {
			selection = tag
		} label: {
			HStack {
				ZStack {
					Circle()
						.foregroundColor(.blue)
						.frame(width: 32, height: 32)
					if selection == tag {
						Circle()
							.foregroundColor(Color.white)
							.frame(width: 16, height: 16)
					}
				}
				Text(tag.title)
			}
		}
		.buttonStyle(.plain)
	}
}

struct RadioButton_Previews: PreviewProvider {
	static var previews: some View {
		RadioButton(tag: UserFindStatus.friend, selection: Binding<UserFindStatus>.constant(.friend))
	}
}

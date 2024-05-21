//
//  CountryTextField.swift
//  Coliver
//
//  Created by Никита Шляхов on 17.05.2024.
//

import SwiftUI

struct CountryTextField: View {
    @Binding var selectedCountry: String
    @State private var showCountryPicker: Bool = false

    var body: some View {
        VStack {
            PlainTextField("Страна", text: $selectedCountry, size: .usuall)
                .onTapGesture {
                    showCountryPicker.toggle()
                }
                .overlay(alignment: .trailing) {
                    if !selectedCountry.isEmpty {
                        Button(action: {
                            selectedCountry = ""
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 5)
                    }
                }
            
            if showCountryPicker {
                CountrySelector(selectedCountry: $selectedCountry)
                    .onChange(of: selectedCountry) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCountryPicker = false
                        }
                    }
            }
        }
    }
}

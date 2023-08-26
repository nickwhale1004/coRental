//
//  TitledProtocol.swift
//  Coliver
//
//  Created by Никита Шляхов on 20.05.2023.
//

protocol TitledProtocol: Hashable, Equatable {
	var title: String { get }
}

//
//  JSONEncoder+Extension.swift
//  Coliver
//
//  Created by Никита Шляхов on 13.02.2024.
//

import Foundation

extension JSONEncoder {
    static var smartEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

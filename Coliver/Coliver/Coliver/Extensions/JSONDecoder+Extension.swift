//
//  JSONDecoder+Extension.swift
//  Coliver
//
//  Created by Никита Шляхов on 13.02.2024.
//

import Foundation

extension JSONDecoder {
    static var smartDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            guard let date = ISO8601DateFormatter().date(from: dateStr) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
            }
            return date
        }
        return decoder
    }
}

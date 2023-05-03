//
//  RedisError.swift
//  
//
//  Created by Andrew Barba on 5/3/23.
//

import Foundation

public struct RedisError: Decodable, LocalizedError {
    public var error: String

    public var errorDescription: String? {
        error
    }
}

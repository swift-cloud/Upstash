//
//  RedisResult.swift
//  
//
//  Created by Andrew Barba on 5/3/23.
//

import AnyCodable
import Foundation

public struct RedisResult: Decodable {
    private var result: AnyDecodable

    public var value: Any? {
        return result.value
    }

    /// Value of the claim as `String`.
    public var string: String? {
        return self.value as? String
    }

    /// Value of the claim as `Bool`.
    public var bool: Bool? {
        return self.value as? Bool
    }

    /// Value of the claim as `Double`.
    public var double: Double? {
        var double: Double?
        if let string = self.string {
            double = Double(string)
        } else if self.bool == nil {
            double = self.value as? Double
        }
        return double
    }

    /// Value of the claim as `Int`.
    public var int: Int? {
        var integer: Int?
        if let string = self.string {
            integer = Int(string)
        } else if let double = self.double {
            integer = Int(double)
        } else if self.bool == nil {
            integer = self.value as? Int
        }
        return integer
    }

    /// Value of the claim as `Date`.
    public var date: Date? {
        guard let timestamp: TimeInterval = self.double else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    /// Value of the claim as `[String]`.
    public var array: [String]? {
        if let array = self.value as? [String] {
            return array
        }
        if let value = self.string {
            return [value]
        }
        return nil
    }

    /// Value of the claim as `[String: Any]`.
    public var dictionary: [String: Any]? {
        if let dict = self.value as? [String: Any] {
            return dict
        }
        return nil
    }

    /// Value of the claim as `Decodable`.
    public func decode<T>(_ type: T.Type, decoder: JSONDecoder = .init()) throws -> T where T: Decodable {
        if let value = value as? T {
            return value
        }
        guard let text = self.value as? String else {
            throw RedisError(error: "Invalid json value")
        }
        return try decoder.decode(type, from: .init(text.utf8))
    }

    /// Value of the claim as `Decodable`.
    public func decode<T>(decoder: JSONDecoder = .init()) throws -> T where T: Decodable {
        if let value = value as? T {
            return value
        }
        guard let text = self.value as? String else {
            throw RedisError(error: "Invalid json value")
        }
        return try decoder.decode(T.self, from: .init(text.utf8))
    }
}

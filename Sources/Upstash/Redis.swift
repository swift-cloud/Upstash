//
//  Redis.swift
//  
//
//  Created by Andrew Barba on 12/4/22.
//

import AnyCodable
import Compute

public struct RedisClient: Sendable {

    public let hostname: String

    private let token: String

    public init(hostname: String, token: String) {
        self.hostname = hostname.replacingOccurrences(of: "https://", with: "")
        self.token = token
    }
}

// MARK: - Exec

extension RedisClient {

    @discardableResult
    public func exec(_ cmd: String, _ args: [Any]) async throws -> RedisResult {
        return try await exec(.init(cmd, args))
    }

    @discardableResult
    public func exec(_ cmd: String, _ args: Any...) async throws -> RedisResult {
        return try await exec(.init(cmd, args))
    }

    @discardableResult
    public func exec(_ command: RedisCommand) async throws -> RedisResult {
        let url = "https://\(hostname)"
        let res = try await fetch(url, .options(
            method: .post,
            body: .json(command.prepared()),
            headers: [HTTPHeader.authorization.rawValue: "Bearer \(token)"]
        ))
        guard res.ok else {
            let error: RedisError = try await res.decode()
            throw error
        }
        return try await res.decode()
    }
}

// MARK: - Get

extension RedisClient {

    public func get(_ key: String, cachePolicy: CachePolicy = .origin) async throws -> RedisResult {
        let url = "https://\(hostname)/get/\(key)"
        let res = try await fetch(url, .options(
            method: .get,
            headers: [HTTPHeader.authorization.rawValue: "Bearer \(token)"],
            cachePolicy: cachePolicy
        ))
        guard res.ok else {
            let error: RedisError = try await res.decode()
            throw error
        }
        return try await res.decode()
    }
}

// MARK: - Set

extension RedisClient {

    @discardableResult
    public func set<T>(
        _ key: String,
        _ value: T,
        encoder: JSONEncoder = .init(),
        formatting: JSONEncoder.OutputFormatting = [.sortedKeys]
    ) async throws -> RedisResult where T: Encodable {
        let data = try encoder.encode(value)
        let text = String(data: data, encoding: .utf8)!
        return try await exec("set", key, text)
    }

    @discardableResult
    public func set(
        _ key: String,
        _ jsonObject: [String: Any],
        options: JSONSerialization.WritingOptions = [.sortedKeys]
    ) async throws -> RedisResult {
        let data = try JSONSerialization.data(withJSONObject: jsonObject)
        let text = String(data: data, encoding: .utf8)!
        return try await exec("set", key, text)
    }

    @discardableResult
    public func set(
        _ key: String,
        _ jsonArray: [Any],
        options: JSONSerialization.WritingOptions = [.sortedKeys]
    ) async throws -> RedisResult {
        let data = try JSONSerialization.data(withJSONObject: jsonArray)
        let text = String(data: data, encoding: .utf8)!
        return try await exec("set", key, text)
    }

    @discardableResult
    public func set(_ key: String, _ value: String) async throws -> RedisResult {
        return try await exec("set", key, value)
    }

    @discardableResult
    public func set(_ key: String, _ value: Bool) async throws -> RedisResult {
        return try await exec("set", key, value)
    }

    @discardableResult
    public func set(_ key: String, _ value: any Numeric) async throws -> RedisResult {
        return try await exec("set", key, value)
    }
}

// MARK: - Pipeline

extension RedisClient {

    public func pipeline(_ commands: [RedisCommand]) async throws -> [RedisResponse] {
        let url = "https://\(hostname)/pipeline"
        let res = try await fetch(url, .options(
            method: .post,
            body: .json(commands.map { $0.prepared() }),
            headers: [HTTPHeader.authorization.rawValue: "Bearer \(token)"]
        ))
        guard res.ok else {
            let error: RedisError = try await res.decode()
            throw error
        }
        return try await res.decode()
    }
}

// MARK: - Transaction

extension RedisClient {

    public func transaction(_ commands: [RedisCommand]) async throws -> [RedisResponse] {
        let url = "https://\(hostname)/multi-exec"
        let res = try await fetch(url, .options(
            method: .post,
            body: .json(commands.map { $0.prepared() }),
            headers: [HTTPHeader.authorization.rawValue: "Bearer \(token)"]
        ))
        guard res.ok else {
            let error: RedisError = try await res.decode()
            throw error
        }
        return try await res.decode()
    }
}

// MARK: - Command

public struct RedisCommand {
    public let cmd: String
    public let args: [Any]

    public init(_ cmd: String, _ args: Any...) {
        self.cmd = cmd
        self.args = args
    }

    public init(_ cmd: String, _ args: [Any]) {
        self.cmd = cmd
        self.args = args
    }

    fileprivate func prepared() -> [Any] {
        return [cmd.uppercased()] + args
    }
}

// MARK: - Responses

public enum RedisResponse: Decodable {
    case success(_ response: RedisResult)
    case error(_ error: RedisError)

    public var result: RedisResult? {
        switch self {
        case .success(let result):
            return result
        default:
            return nil
        }
    }

    public var error: RedisError? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
}

// MARK: - Result

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

// MARK: - Error

public struct RedisError: Decodable, LocalizedError {
    public var error: String

    public var errorDescription: String? {
        error
    }
}

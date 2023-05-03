//
//  RedisClient.swift
//  
//
//  Created by Andrew Barba on 5/3/23.
//

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

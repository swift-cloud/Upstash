//
//  Redis.swift
//  
//
//  Created by Andrew Barba on 12/4/22.
//

import Compute

public protocol RedisResponse: Decodable {
    associatedtype Result
    var result: Result { get }
}

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

    public func exec<T: Decodable>(_ cmd: String, _ args: [Any]) async throws -> T {
        return try await exec(.init(cmd, args))
    }

    public func exec<T: Decodable>(_ cmd: String, _ args: Any...) async throws -> T {
        return try await exec(.init(cmd, args))
    }

    public func exec<T: Decodable>(_ command: Command) async throws -> T {
        let url = "https://\(hostname)"
        let res = try await fetch(url, .options(
            method: .post,
            body: .json(command.prepared()),
            headers: [HTTPHeader.authorization.rawValue: "Bearer \(token)"]
        ))
        guard res.ok else {
            let error: ExecError = try await res.decode()
            throw error
        }
        let value: ExecResponse<T> = try await res.decode()
        return value.result
    }
}

// MARK: - Get

extension RedisClient {

    public func get<T: Decodable>(_ key: String, cachePolicy: CachePolicy = .origin) async throws -> T {
        let url = "https://\(hostname)/get/\(key)"
        let res = try await fetch(url, .options(
            method: .get,
            headers: [HTTPHeader.authorization.rawValue: "Bearer \(token)"],
            cachePolicy: cachePolicy
        ))
        guard res.ok else {
            let error: ExecError = try await res.decode()
            throw error
        }
        let value: ExecResponse<T> = try await res.decode()
        return value.result
    }
}

// MARK: - Pipeline

extension RedisClient {

    public func pipeline(_ commands: [Command]) async throws -> [Any] {
        let url = "https://\(hostname)/pipeline"
        let res = try await fetch(url, .options(
            method: .post,
            body: .json(commands.map { $0.prepared() }),
            headers: [HTTPHeader.authorization.rawValue: "Bearer \(token)"]
        ))
        guard res.ok else {
            let error: ExecError = try await res.decode()
            throw error
        }
        return try await res.jsonArray()
    }
}

// MARK: - Transaction

extension RedisClient {

    public func transaction(_ commands: [Command]) async throws -> [Any] {
        let url = "https://\(hostname)/multi-exec"
        let res = try await fetch(url, .options(
            method: .post,
            body: .json(commands.map { $0.prepared() }),
            headers: [HTTPHeader.authorization.rawValue: "Bearer \(token)"]
        ))
        guard res.ok else {
            let error: ExecError = try await res.decode()
            throw error
        }
        return try await res.jsonArray()
    }
}

// MARK: - Responses

extension RedisClient {

    public struct Command {
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

    public struct ExecResponse<T: Decodable>: RedisResponse {
        public var result: T
    }

    public struct ExecError: Decodable, LocalizedError {
        public var error: String

        public var errorDescription: String? {
            error
        }
    }
}

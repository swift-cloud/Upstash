//
//  RedisCommand.swift
//  
//
//  Created by Andrew Barba on 5/3/23.
//

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

    internal func prepared() -> [Any] {
        return [cmd.uppercased()] + args
    }
}

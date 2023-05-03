//
//  RedisResponse.swift
//  
//
//  Created by Andrew Barba on 5/3/23.
//

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

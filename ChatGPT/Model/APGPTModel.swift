//
//  APGPTModel.swift
//  ChatGPT
//
//  Created by Wykee on 29/01/2023.
//

import Foundation

// MARK: - APGPTModel
struct APGPTModel: Codable {
    let choices: [Choice]
    let created: Int
    let id, model, object: String
    let usage: Usage
}

// MARK: - Choice
struct Choice: Codable {
    let finishReason: String
    let index: Int
    let logprobs: JSONNull?
    let text: String

    enum CodingKeys: String, CodingKey {
        case finishReason = "finish_reason"
        case index, logprobs, text
    }
}

// MARK: - Usage
struct Usage: Codable {
    let completionTokens, promptTokens, totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case completionTokens = "completion_tokens"
        case promptTokens = "prompt_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

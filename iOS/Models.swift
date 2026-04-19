import Foundation
import UIKit

// MARK: - Post

struct Post: Codable, Identifiable {
    let id: Int64
    var content: String
    let idea: String
    let tone: String
    let length: String
    var status: String
    let date: String
}

// MARK: - Image

struct ImageData {
    let base64: String
    let mediaType: String
    let uiImage: UIImage
}

// MARK: - Tone / Length config types

struct ToneConfig {
    let label: String
    let value: String
    let desc: String
}

struct LengthConfig {
    let label: String
    let value: String
    let desc: String
    let words: String
}

// MARK: - API error

enum APIError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server."
        case .apiError(let msg): return msg
        case .emptyResponse: return "Empty response. Try again."
        }
    }
}

// MARK: - Anthropic API response shapes

struct AnthropicResponse: Codable {
    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }
    let content: [ContentBlock]
}

struct AnthropicErrorResponse: Codable {
    struct APIErrorBody: Codable {
        let message: String
    }
    let error: APIErrorBody
}

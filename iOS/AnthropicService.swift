import Foundation

enum AnthropicService {

    // MARK: - Public

    static func generatePost(
        apiKey: String,
        tone: String,
        length: String,
        randomize: Bool,
        idea: String,
        isRegen: Bool,
        image: ImageData?
    ) async throws -> String {

        let prompt = buildPrompt(
            tone: tone, length: length,
            randomize: randomize, idea: idea,
            isRegen: isRegen, hasImage: image != nil
        )

        let messageContent: Any
        if let image = image {
            messageContent = [
                [
                    "type": "image",
                    "source": [
                        "type": "base64",
                        "media_type": image.mediaType,
                        "data": image.base64
                    ]
                ],
                ["type": "text", "text": prompt]
            ]
        } else {
            messageContent = prompt
        }

        let body: [String: Any] = [
            "model": AppConstants.MODEL,
            "max_tokens": AppConstants.MAX_TOKENS,
            "system": AppConstants.CODY_CONTEXT,
            "messages": [["role": "user", "content": messageContent]]
        ]

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard http.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data) {
                throw APIError.apiError(errorResponse.error.message)
            }
            throw APIError.apiError("API error \(http.statusCode)")
        }

        let apiResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        let text = apiResponse.content
            .filter { $0.type == "text" }
            .compactMap { $0.text }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw APIError.emptyResponse
        }

        return text
    }

    // MARK: - Private

    private static func buildPrompt(
        tone: String, length: String,
        randomize: Bool, idea: String,
        isRegen: Bool, hasImage: Bool
    ) -> String {
        let lenConfig = AppConstants.LENGTHS.first { $0.value == length }
        var prompt = "\(AppConstants.TONE_PROMPTS[tone] ?? "")\n\nTarget length: \(lenConfig?.words ?? "").\n"

        if randomize {
            let hook      = AppConstants.HOOKS.randomElement() ?? ""
            let structure = AppConstants.STRUCTURES.randomElement() ?? ""
            let closing   = AppConstants.CLOSINGS.randomElement() ?? ""
            prompt += "\nHook: \(hook)\nStructure: \(structure)\nClosing: \(closing)\n"
        }

        if hasImage {
            prompt += "\nAn image has been provided. Analyze it and incorporate what you see into the post, combined with the idea below.\n"
        }

        let trimmedIdea = idea.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedIdea.isEmpty {
            prompt += "\nIdea or topic: \"\(trimmedIdea)\"\n"
        }

        if isRegen {
            prompt += "\nA previous version exists. Write a completely different version with a different hook, angle, and structure.\n"
        }

        return prompt
    }
}

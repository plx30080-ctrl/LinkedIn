import Foundation
import Combine

final class AppState: ObservableObject {

    @Published var apiKey: String = ""
    @Published var queue: [Post] = []
    @Published var selectedTab: Int = 0

    var queuedCount: Int { queue.filter { $0.status == "queued" }.count }

    init() {
        apiKey = UserDefaults.standard.string(forKey: AppConstants.API_KEY_STORAGE) ?? ""
        if let data = UserDefaults.standard.data(forKey: AppConstants.QUEUE_KEY),
           let saved = try? JSONDecoder().decode([Post].self, from: data) {
            queue = saved
        }
    }

    // MARK: - API key

    func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        apiKey = trimmed
        UserDefaults.standard.set(trimmed, forKey: AppConstants.API_KEY_STORAGE)
    }

    func removeAPIKey() {
        apiKey = ""
        UserDefaults.standard.removeObject(forKey: AppConstants.API_KEY_STORAGE)
    }

    // MARK: - Queue

    func addToQueue(_ post: Post) {
        queue.insert(post, at: 0)
        persistQueue()
    }

    func markPosted(id: Int64) {
        if let idx = queue.firstIndex(where: { $0.id == id }) {
            queue[idx].status = "posted"
            persistQueue()
        }
    }

    func removeFromQueue(id: Int64) {
        queue.removeAll { $0.id == id }
        persistQueue()
    }

    func navigateToQueue() {
        selectedTab = 1
    }

    // MARK: - Private

    private func persistQueue() {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: AppConstants.QUEUE_KEY)
        }
    }
}

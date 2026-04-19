import SwiftUI

struct QueueView: View {
    @EnvironmentObject var appState: AppState
    @State private var copiedId: Int64?

    var body: some View {
        NavigationStack {
            Group {
                if appState.queue.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(appState.queue) { post in
                            PostCard(
                                post: post,
                                isCopied: copiedId == post.id,
                                onCopy: { copy(post) },
                                onMarkPosted: { appState.markPosted(id: post.id) },
                                onRemove: { appState.removeFromQueue(id: post.id) }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Queue")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Queue is empty")
                .font(.headline)
            Text("Generate a post and add it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private func copy(_ post: Post) {
        UIPasteboard.general.string = post.content
        copiedId = post.id
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if copiedId == post.id { copiedId = nil }
        }
    }
}

// MARK: - Post Card

struct PostCard: View {
    let post: Post
    let isCopied: Bool
    let onCopy: () -> Void
    let onMarkPosted: () -> Void
    let onRemove: () -> Void

    private var isPosted: Bool { post.status == "posted" }

    private var toneName: String {
        AppConstants.TONES.first { $0.value == post.tone }?.label ?? post.tone.capitalized
    }

    private var lengthName: String {
        AppConstants.LENGTHS.first { $0.value == post.length }?.label ?? post.length.capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Meta row
            HStack(spacing: 6) {
                statusBadge
                chip(toneName)
                chip(lengthName)
                Spacer()
                Text(post.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Post content
            Text(post.content)
                .font(.body)

            // Source idea
            if !post.idea.isEmpty {
                Text("Idea: \(post.idea)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Action buttons
            HStack(spacing: 8) {
                actionButton(isCopied ? "Copied!" : "Copy", style: .secondary, action: onCopy)

                if !isPosted {
                    actionButton("Mark Posted", style: .green, action: onMarkPosted)
                }

                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isPosted ? 0.65 : 1.0)
    }

    private var statusBadge: some View {
        Label(
            isPosted ? "Posted" : "Queued",
            systemImage: isPosted ? "checkmark.circle.fill" : "clock"
        )
        .font(.caption.weight(.medium))
        .foregroundStyle(isPosted ? .green : .blue)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isPosted ? Color.green : Color.blue).opacity(0.12))
        .clipShape(Capsule())
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
    }

    private enum ButtonStyle { case secondary, green }

    private func actionButton(_ title: String, style: ButtonStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(style == .green ? Color.green : Color(.systemGray5))
                .foregroundStyle(style == .green ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .font(.subheadline.weight(.medium))
        }
    }
}

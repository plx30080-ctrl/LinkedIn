import SwiftUI
import PhotosUI

struct CreateView: View {
    @EnvironmentObject var appState: AppState

    // Inputs
    @State private var idea = ""
    @State private var tone = "practical"
    @State private var length = "medium"
    @State private var randomize = true
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: ImageData?

    // Output
    @State private var draft = ""
    @State private var hadResult = false
    @State private var loading = false
    @State private var error = ""
    @State private var copied = false

    // MARK: - Computed

    private var canGenerate: Bool {
        !loading
            && (!idea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || imageData != nil)
            && !appState.apiKey.isEmpty
    }

    private var wordCount: Int {
        draft.split { $0.isWhitespace }.filter { !$0.isEmpty }.count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    ideaSection
                    imageSection
                    toneSection
                    lengthSection
                    randomizeSection
                    actionButtons

                    if appState.apiKey.isEmpty {
                        warningBanner("Add your Anthropic API key in Settings to get started.", color: .orange)
                    }
                    if !error.isEmpty {
                        warningBanner(error, color: .red)
                    }
                    if loading {
                        loadingIndicator
                    }
                    if hadResult && !loading {
                        draftSection
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LinkedIn Content Tool")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Post Smarter, Not More")
                .font(.largeTitle.bold())
            Text("Drop an idea. Get a post. Approve and queue it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var ideaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your Idea", systemImage: "lightbulb")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $idea)
                    .frame(minHeight: 90)
                    .padding(6)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                if idea.isEmpty {
                    Text("A win, a frustration, something you built, a lesson learned...")
                        .foregroundStyle(.tertiary)
                        .padding(14)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Image (optional)", systemImage: "photo")
                .font(.headline)

            if let imageData {
                HStack(spacing: 12) {
                    Image(uiImage: imageData.uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image loaded.")
                            .font(.subheadline)
                        Text("Claude will analyze and incorporate it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Remove", role: .destructive) {
                            self.imageData = nil
                            self.selectedPhoto = nil
                        }
                        .font(.caption)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Upload Image", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .onChange(of: selectedPhoto) { _, item in
                    Task {
                        guard let item,
                              let data = try? await item.loadTransferable(type: Data.self),
                              let uiImage = UIImage(data: data)
                        else { return }
                        self.imageData = ImageProcessor.compress(uiImage)
                    }
                }
                Text("JPG, PNG, GIF, WEBP. Compressed automatically before sending.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tone", systemImage: "speaker.wave.2")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AppConstants.TONES, id: \.value) { t in
                        Button(t.label) { tone = t.value }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(tone == t.value ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundStyle(tone == t.value ? .white : .primary)
                            .clipShape(Capsule())
                            .animation(.easeInOut(duration: 0.15), value: tone)
                    }
                }
            }
            if let desc = AppConstants.TONES.first(where: { $0.value == tone })?.desc {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var lengthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Length", systemImage: "text.alignleft")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(AppConstants.LENGTHS, id: \.value) { l in
                    Button(l.label) { length = l.value }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(length == l.value ? Color.blue : Color(.secondarySystemBackground))
                        .foregroundStyle(length == l.value ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .animation(.easeInOut(duration: 0.15), value: length)
                }
            }
            if let desc = AppConstants.LENGTHS.first(where: { $0.value == length })?.desc {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var randomizeSection: some View {
        Toggle(isOn: $randomize) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Randomize hook + structure")
                    .font(.subheadline)
                Text("Picks a random hook, closing, and structure each time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await run(isRegen: false) }
            } label: {
                Text(loading ? "Generating..." : "Generate Post")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canGenerate ? Color.blue : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .font(.headline)
            }
            .disabled(!canGenerate)

            if hadResult && !loading {
                Button {
                    Task { await run(isRegen: true) }
                } label: {
                    Text("Try Again")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .font(.headline)
                }
            }
        }
    }

    private var loadingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Writing your post...")
                .foregroundStyle(.secondary)
        }
    }

    private var draftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack {
                Label("Edit Before Queuing", systemImage: "pencil")
                    .font(.headline)
                Spacer()
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $draft)
                .frame(minHeight: 200)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 12) {
                Button {
                    addToQueue()
                } label: {
                    Text("Add to Queue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color.gray.opacity(0.4) : Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .font(.headline)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    copyPost()
                } label: {
                    Text(copied ? "Copied!" : "Copy Post")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Helpers

    private func warningBanner(_ message: String, color: Color) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(color)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions

    private func run(isRegen: Bool) async {
        guard !appState.apiKey.isEmpty else {
            error = "Add your API key in Settings first."
            return
        }
        loading = true
        error = ""
        if !isRegen {
            draft = ""
            hadResult = false
        }
        do {
            let text = try await AnthropicService.generatePost(
                apiKey: appState.apiKey,
                tone: tone,
                length: length,
                randomize: randomize,
                idea: idea,
                isRegen: isRegen,
                image: imageData
            )
            draft = text
            hadResult = true
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private func addToQueue() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let post = Post(
            id: Int64(Date().timeIntervalSince1970 * 1000),
            content: trimmed,
            idea: idea,
            tone: tone,
            length: length,
            status: "queued",
            date: formatter.string(from: Date())
        )
        appState.addToQueue(post)
        appState.navigateToQueue()
    }

    private func copyPost() {
        UIPasteboard.general.string = draft
        copied = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            copied = false
        }
    }
}

import SwiftUI
import PhotosUI
import AVFoundation
import AVKit
import UniformTypeIdentifiers
import UIKit

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var inputURL: URL?
    @State private var videoName = ""
    @State private var isImporting = false
    @State private var importMessage = "Choose a video from your library"
    @State private var showEditor = false

    @State private var keepDuration = 3.0
    @State private var removeDuration = 1.0
    @State private var keepFirst = true
    @State private var isExporting = false
    @State private var progress = 0.0
    @State private var status = "Ready when you are."
    @State private var outputURL: URL?
    @State private var showShare = false
    @State private var errorMessage: String?
    @State private var previewPlayer: AVPlayer?

    private let accent = Color(red: 0.20, green: 0.78, blue: 0.96)
    private let background = Color(red: 0.035, green: 0.045, blue: 0.065)

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        header

                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 12) {
                                Image(systemName: "film.stack")
                                    .font(.system(size: 23, weight: .semibold))
                                    .foregroundStyle(accent)
                                    .frame(width: 48, height: 48)
                                    .background(accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 15))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Start a project")
                                        .font(.title3.bold())
                                    Text("Import a video to create alternating clips")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            PhotosPicker(selection: $selectedItem, matching: .videos) {
                                HStack(spacing: 14) {
                                    Image(systemName: "plus.rectangle.on.rectangle")
                                        .font(.system(size: 25, weight: .medium))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(inputURL == nil ? "Choose video" : "Choose another video")
                                            .font(.headline)
                                        Text("Photos library · MOV · MP4")
                                            .font(.caption)
                                            .opacity(0.8)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                }
                                .foregroundStyle(.white)
                                .padding(18)
                                .frame(maxWidth: .infinity, minHeight: 84)
                                .background(
                                    LinearGradient(colors: [accent.opacity(0.95), Color.blue.opacity(0.85)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                                    in: RoundedRectangle(cornerRadius: 20)
                                )
                            }
                            .disabled(isImporting || isExporting)
                            .onChange(of: selectedItem) { item in
                                guard let item else { return }
                                Task { await importVideo(item) }
                            }

                            if isImporting {
                                HStack(spacing: 12) {
                                    ProgressView().tint(accent)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Importing video…").font(.subheadline.weight(.semibold))
                                        Text("Large 4K files may take a little time to become available.")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 15))
                            } else if let inputURL {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Video imported").font(.subheadline.weight(.semibold))
                                        Text(videoName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.green.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
                            } else {
                                Text(importMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button {
                                showEditor = true
                            } label: {
                                HStack {
                                    Text("Continue to Editor")
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .font(.headline)
                                .foregroundStyle(inputURL == nil || isImporting ? .white.opacity(0.55) : background)
                                .padding(.horizontal, 18)
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .background(inputURL == nil || isImporting ? Color.white.opacity(0.10) : accent,
                                            in: RoundedRectangle(cornerRadius: 17))
                            }
                            .disabled(inputURL == nil || isImporting)
                        }
                        .padding(20)
                        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 26))

                        VStack(alignment: .leading, spacing: 12) {
                            Label("How it works", systemImage: "sparkles")
                                .font(.headline)
                            instructionRow(number: "01", title: "Import once", detail: "Select your original video.")
                            instructionRow(number: "02", title: "Set custom intervals", detail: "Choose separate keep and remove durations.")
                            instructionRow(number: "03", title: "Choose a cutting mode", detail: "Start by keeping or removing, then export.")
                        }
                        .padding(20)
                        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 24))

                        Text("Your original video is never modified. Processing stays on your iPhone.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 18)
                    }
                    .frame(maxWidth: 680)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showEditor) {
                editorScreen
                    .toolbar(.hidden, for: .navigationBar)
            }
            .sheet(isPresented: $showShare) {
                if let outputURL { ShareSheet(items: [outputURL]) }
            }
            .alert("AutoCut Studio", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .tint(accent)
        .preferredColorScheme(.dark)
    }

    private var horizontalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 34 : 20
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AUTOCUT STUDIO")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(accent)
                Spacer()
                Image(systemName: "waveform.path")
                    .font(.title2)
                    .foregroundStyle(accent.opacity(0.8))
            }
            Text("Make every cut\ncount.")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.75)
                .lineLimit(2)
            Text("Fast alternating video cutter")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func instructionRow(number: String, title: String, detail: String) -> some View {
        HStack(spacing: 13) {
            Text(number)
                .font(.caption.monospaced().bold())
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var editorScreen: some View {
        ZStack {
            background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button {
                            showEditor = false
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                        }
                        Spacer()
                        Text("EDITOR")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundStyle(accent)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(videoName.isEmpty ? "Your video" : videoName)
                            .font(.headline)
                            .lineLimit(1)
                        if let previewPlayer {
                            VideoPlayer(player: previewPlayer)
                                .frame(height: previewHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        } else {
                            ZStack {
                                Color.black
                                Image(systemName: "play.rectangle")
                                    .font(.system(size: 42))
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                            .frame(height: previewHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding(16)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 23))

                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Custom intervals").font(.title3.bold())
                            Text("Choose how long each kept and removed section lasts.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        durationControl(title: "Keep duration", value: $keepDuration, tint: .green)
                        Divider().overlay(.white.opacity(0.08))
                        durationControl(title: "Remove duration", value: $removeDuration, tint: .red)

                        HStack(spacing: 5) {
                            intervalPreviewBlock(title: "KEEP", duration: keepDuration, color: .green)
                            intervalPreviewBlock(title: "REMOVE", duration: removeDuration, color: .red)
                        }
                        .frame(height: 58)
                        Text(String(format: "One complete cycle: %.1f seconds", keepDuration + removeDuration))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cutting mode").font(.title3.bold())
                        modeOption(title: "Keep alternate clips",
                                   detail: String(format: "Keep %.1fs, remove %.1fs, repeat…", keepDuration, removeDuration), value: true)
                        modeOption(title: "Remove alternate clips",
                                   detail: String(format: "Remove %.1fs, keep %.1fs, repeat…", removeDuration, keepDuration), value: false)
                    }
                    .padding(18)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))

                    Button {
                        Task { await exportVideo() }
                    } label: {
                        HStack {
                            if isExporting { ProgressView().tint(.black) }
                            Text(isExporting ? "Processing video…" : "Export edited video")
                            Spacer()
                            Image(systemName: "scissors")
                        }
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 19)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(accent, in: RoundedRectangle(cornerRadius: 17))
                    }
                    .disabled(inputURL == nil || isExporting)

                    if isExporting {
                        ProgressView(value: progress).tint(accent)
                        Text("\(Int(progress * 100))% · \(status)")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text(status).font(.caption).foregroundStyle(.secondary)
                    }

                    if outputURL != nil {
                        Button { showShare = true } label: {
                            Label("Save or share finished video", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(.green.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .frame(maxWidth: 680)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, 35)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            if let inputURL {
                previewPlayer = AVPlayer(url: inputURL)
            }
        }
        .onDisappear {
            previewPlayer?.pause()
        }
    }

    private var previewHeight: CGFloat {
        min(max(UIScreen.main.bounds.width * 0.52, 190), 360)
    }

    private func durationControl(title: String, value: Binding<Double>, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: "%.1f sec", value.wrappedValue))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(tint)
            }
            Slider(value: value, in: 0.1...30, step: 0.1)
                .tint(tint)
            HStack {
                Text("0.1 sec")
                Spacer()
                Text("30 sec")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }

    private func intervalPreviewBlock(title: String, duration: Double, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.caption2.weight(.bold))
            Text(String(format: "%.1fs", duration)).font(.headline.monospacedDigit())
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.opacity(0.78), in: RoundedRectangle(cornerRadius: 10))
    }

    private func modeOption(title: String, detail: String, value: Bool) -> some View {
        Button { keepFirst = value } label: {
            HStack(spacing: 13) {
                Image(systemName: keepFirst == value ? "largecircle.fill.circle" : "circle")
                    .font(.title2)
                    .foregroundStyle(keepFirst == value ? accent : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(keepFirst == value ? accent.opacity(0.12) : .white.opacity(0.035),
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(keepFirst == value ? accent.opacity(0.45) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // FileRepresentation transfers a file URL instead of loading the full movie into Data.
    // This avoids holding an entire 4K video in memory during import.
    @MainActor
    private func importVideo(_ item: PhotosPickerItem) async {
        isImporting = true
        importMessage = "Preparing your video…"
        status = "Importing…"
        outputURL = nil
        previewPlayer?.pause()
        previewPlayer = nil
        defer { isImporting = false }

        do {
            guard let movie = try await item.loadTransferable(type: ImportedMovie.self) else {
                throw AutoCutError.cannotLoad
            }
            inputURL = movie.url
            videoName = movie.url.lastPathComponent
            importMessage = "Video ready"
            status = "Video ready. Adjust your cutting settings."
            selectedItem = nil
        } catch {
            importMessage = "Import failed. Please try selecting the video again."
            errorMessage = "Could not import this video: \(error.localizedDescription)"
            selectedItem = nil
        }
    }

    @MainActor
    private func exportVideo() async {
        guard let inputURL else { return }
        isExporting = true
        progress = 0
        outputURL = nil
        status = "Preparing video…"
        defer { isExporting = false }

        do {
            let asset = AVURLAsset(url: inputURL)
            let durationTime = try await asset.load(.duration)
            let duration = CMTimeGetSeconds(durationTime)
            guard duration.isFinite, duration > 0 else { throw AutoCutError.invalidDuration }

            let composition = AVMutableComposition()
            guard let sourceVideo = try await asset.loadTracks(withMediaType: .video).first,
                  let destinationVideo = composition.addMutableTrack(
                    withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid
                  ) else { throw AutoCutError.noVideoTrack }

            let videoTransform = try await sourceVideo.load(.preferredTransform)
            destinationVideo.preferredTransform = videoTransform

            let sourceAudio = try await asset.loadTracks(withMediaType: .audio).first
            let destinationAudio = sourceAudio == nil ? nil : composition.addMutableTrack(
                withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
            )

            guard keepDuration > 0, removeDuration > 0 else {
                throw AutoCutError.invalidIntervals
            }

            var cursor = 0.0
            var index = 0
            var insertAt = CMTime.zero
            var keptDuration = 0.0

            while cursor < duration - 0.0001 {
                let shouldKeep = keepFirst ? index.isMultiple(of: 2) : !index.isMultiple(of: 2)
                let segmentDuration = shouldKeep ? keepDuration : removeDuration
                let end = min(cursor + segmentDuration, duration)
                if shouldKeep && end - cursor > 0.02 {
                    let startTime = CMTime(seconds: cursor, preferredTimescale: 600)
                    let endTime = CMTime(seconds: end, preferredTimescale: 600)
                    let range = CMTimeRange(start: startTime, end: endTime)
                    try destinationVideo.insertTimeRange(range, of: sourceVideo, at: insertAt)

                    if let sourceAudio, let destinationAudio {
                        let audioTimeRange = try await sourceAudio.load(.timeRange)
                        let audioEnd = min(endTime, CMTimeRangeGetEnd(audioTimeRange))
                        if CMTimeCompare(audioEnd, startTime) > 0 {
                            let audioRange = CMTimeRange(start: startTime, end: audioEnd)
                            try destinationAudio.insertTimeRange(audioRange, of: sourceAudio, at: insertAt)
                        }
                    }
                    insertAt = CMTimeAdd(insertAt, CMTime(seconds: end - cursor, preferredTimescale: 600))
                    keptDuration += end - cursor
                }
                cursor = end
                index += 1
            }

            guard keptDuration > 0 else { throw AutoCutError.noSegments }
            let output = FileManager.default.temporaryDirectory
                .appendingPathComponent("AutoCut_\(UUID().uuidString).mp4")
            guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                throw AutoCutError.exportUnavailable
            }
            guard exporter.supportedFileTypes.contains(.mp4) else {
                throw AutoCutError.unsupportedOutput
            }
            exporter.outputURL = output
            exporter.outputFileType = .mp4
            exporter.shouldOptimizeForNetworkUse = true

            status = "Exporting edited video…"
            let progressTask = Task { @MainActor in
                while !Task.isCancelled {
                    progress = Double(exporter.progress)
                    if exporter.status != .exporting { break }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
            await withCheckedContinuation { continuation in
                exporter.exportAsynchronously { continuation.resume() }
            }
            progressTask.cancel()

            guard exporter.status == .completed else {
                throw exporter.error ?? AutoCutError.exportFailed
            }
            progress = 1
            outputURL = output
            status = "Export complete. Your original video is unchanged."
        } catch {
            status = "Export failed."
            errorMessage = error.localizedDescription
        }
    }
}

struct ImportedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let sourceURL = received.file
            let fileExtension = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
            let destinationURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("AutoCut_Import_\(UUID().uuidString)")
                .appendingPathExtension(fileExtension)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return ImportedMovie(url: destinationURL)
        }
    }
}

enum AutoCutError: LocalizedError {
    case cannotLoad, invalidDuration, invalidIntervals, noVideoTrack, noSegments, exportUnavailable, unsupportedOutput, exportFailed

    var errorDescription: String? {
        switch self {
        case .cannotLoad: return "The selected video could not be read."
        case .invalidDuration: return "The video's duration could not be determined."
        case .invalidIntervals: return "Keep and remove durations must both be greater than zero."
        case .noVideoTrack: return "No video track was found in this file."
        case .noSegments: return "No clips remain. Choose the other cutting mode or a shorter interval."
        case .exportUnavailable: return "The video export session could not be created."
        case .unsupportedOutput: return "This video cannot currently be exported as MP4 on this device."
        case .exportFailed: return "The video export could not be completed."
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

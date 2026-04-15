//  FeedCell.swift
//  BrightcoveProject


//  FeedCell.swift
//  BrightcoveProject

import SwiftUI
import AVKit

struct FeedCell: View {
    let video: Video
    @Binding var navigationPath: NavigationPath
    @ObservedObject var viewModel: VideoViewModel

    @State private var player: AVPlayer? = nil
    @State private var isVisible  = false
    @State private var isPlaying  = false
    @State private var isReady    = false
    @State private var isMuted    = false
    @State private var progress: Double = 0
    @State private var duration: Double = 1
    @State private var timeObserver: Any? = nil

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // MARK: - Thumbnail mientras carga
            if !isReady, let thumb = video.thumbnailURL, let url = URL(string: thumb) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
            }

            // MARK: - Video Player
            if let player = player {
                CustomVideoPlayer(player: player)
                    .ignoresSafeArea()
                    .containerRelativeFrame([.horizontal, .vertical])
            }

            // MARK: - Tap play/pause
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { togglePlayPause() }

            // MARK: - Icono pausa
            if !isPlaying && isReady {
                Image(systemName: "pause.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.8))
                    .transition(.opacity)
            }

            // MARK: - Overlay UI
            VStack(spacing: 0) {

                // Botón mute — arriba a la derecha
                HStack {
                    Spacer()
                    Button {
                        toggleMute()
                    } label: {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 60)
                }

                Spacer()

                // Info + botones laterales
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Carlos Cordova")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Button {
                            navigationPath.append(video)
                        } label: {
                            Text("Video info")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .underline()
                        }
                        Text(video.name)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    Spacer()
                    VStack(spacing: 28) {
                        Circle()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.gray.opacity(0.8))
                        Button {
                            haptic.impactOccurred()
                        } label: {
                            VStack {
                                Image(systemName: "heart.fill")
                                    .resizable().frame(width: 28, height: 28)
                                    .foregroundColor(.white)
                                Text("1").font(.caption).foregroundColor(.white).bold()
                            }
                        }
                        Button {} label: {
                            VStack {
                                Image(systemName: "ellipsis.bubble.fill")
                                    .resizable().frame(width: 28, height: 28)
                                    .foregroundColor(.white)
                                Text("1").font(.caption).foregroundColor(.white).bold()
                            }
                        }
                        Button {} label: {
                            Image(systemName: "bookmark.fill")
                                .resizable().frame(width: 22, height: 28)
                                .foregroundColor(.white)
                        }
                        Button {} label: {
                            Image(systemName: "arrowshape.turn.up.right.fill")
                                .resizable().frame(width: 28, height: 28)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)

                // MARK: - Barra de progreso
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .foregroundColor(.white.opacity(0.3))
                            .frame(height: 3)
                        Rectangle()
                            .foregroundColor(.white)
                            .frame(
                                width: geo.size.width * CGFloat(progress / max(duration, 1)),
                                height: 3
                            )
                    }
                }
                .frame(height: 3)
                .padding(.horizontal)
                .padding(.bottom, 95) // ← sobre el tab bar
            }
        }
        .onAppear { handleAppear() }
        .onDisappear { handleDisappear() }
        .onReceive(NotificationCenter.default.publisher(for: .pauseAllVideos)) { notif in
            let activeID = notif.userInfo?["activeID"] as? String
            if activeID != video.id {
                player?.pause()
                isPlaying = false
            }
        }
        .onChange(of: viewModel.videoURL(for: video.id)) { _, newURL in
            guard player == nil, isVisible else { return }
            if let urlString = newURL, let url = URL(string: urlString) {
                setupPlayer(url: url)
            }
        }
    }

    // MARK: - Lifecycle
    private func handleAppear() {
        isVisible = true
        haptic.prepare()

        if let existingPlayer = player {
            NotificationCenter.default.post(
                name: .pauseAllVideos,
                object: nil,
                userInfo: ["activeID": video.id]
            )
            existingPlayer.play()
            isPlaying = true
            return
        }

        if let urlString = viewModel.videoURL(for: video.id),
           let url = URL(string: urlString) {
            setupPlayer(url: url)
            return
        }

        Task { await viewModel.loadSourceIfNeeded(for: video.id) }
    }

    private func handleDisappear() {
        isVisible = false
        isPlaying = false
        isReady   = false
        progress  = 0
        removeTimeObserver()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }

    // MARK: - Player setup
    private func setupPlayer(url: URL) {
        guard player == nil else { return }
        let newPlayer = AVPlayer(url: url)
        newPlayer.actionAtItemEnd = .none
        newPlayer.isMuted = isMuted
        player = newPlayer
        isReady = true

        // Loop automático
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            newPlayer.seek(to: .zero)
            newPlayer.play()
        }

        addTimeObserver(player: newPlayer)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NotificationCenter.default.post(
                name: .pauseAllVideos,
                object: nil,
                userInfo: ["activeID": video.id]
            )
            if isVisible {
                newPlayer.play()
                isPlaying = true
                haptic.impactOccurred()
            }
        }
    }

    // MARK: - Progreso
    private func addTimeObserver(player: AVPlayer) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { time in
            progress = time.seconds
            if let item = player.currentItem, item.duration.seconds.isFinite {
                duration = item.duration.seconds
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    // MARK: - Controls
    private func togglePlayPause() {
        guard let player = player else { return }
        haptic.impactOccurred()
        withAnimation(.easeInOut(duration: 0.15)) {
            if isPlaying {
                player.pause()
                isPlaying = false
            } else {
                NotificationCenter.default.post(
                    name: .pauseAllVideos,
                    object: nil,
                    userInfo: ["activeID": video.id]
                )
                player.play()
                isPlaying = true
            }
        }
    }

    private func toggleMute() {
        haptic.impactOccurred()
        isMuted = !isMuted
        player?.isMuted = isMuted
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let pauseAllVideos = Notification.Name("pauseAllVideos")
    static let videoUploaded  = Notification.Name("videoUploaded")
}

// MARK: - Preview
#Preview {
    FeedCell(
        video: Video(
            id: "sampleID",
            accountId: "sampleAccount",
            name: "Sample Video",
            createdAt: "2025-08-04",
            state: "ACTIVE",
            createdBy: CreatedBy(type: "user", id: "userID", email: "user@example.com"),
            description: "Sample description",
            tags: ["tag1"]
        ),
        navigationPath: .constant(NavigationPath()),
        viewModel: VideoViewModel()
    )
}

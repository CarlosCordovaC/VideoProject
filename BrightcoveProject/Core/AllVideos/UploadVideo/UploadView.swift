//
//  UploadView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 18/07/25.
//


//  UploadView.swift
//  BrightcoveProject

import SwiftUI
import PhotosUI
import AVKit

struct UploadView: View {
    @StateObject private var viewModel  = UploadViewModel()
    @FocusState  private var focusedField: Field?
    @State private var previewPlayer: AVPlayer? = nil
    @State private var previewURL: URL? = nil

    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    enum Field { case name, description }

    var body: some View {
        ZStack {
            BCTheme.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // MARK: - Header
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .foregroundStyle(BCTheme.accent)
                            .padding(.top, 40)

                        Text("Subir video")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(BCTheme.textPrimary)

                        Text("El video se subirá a tu cuenta de Brightcove")
                            .font(.footnote)
                            .foregroundStyle(BCTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // MARK: - Vista previa del video seleccionado
                    if let player = previewPlayer {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vista previa")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(BCTheme.textSecondary)

                            VideoPlayer(player: player)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(BCTheme.accent.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }

                    // MARK: - Selector de video
                    PhotosPicker(
                        selection: $viewModel.selectedItem,
                        matching: .videos
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.selectedItem == nil
                                  ? "video.badge.plus"
                                  : "arrow.triangle.2.circlepath.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(viewModel.selectedItem == nil
                                                 ? BCTheme.textSecondary
                                                 : BCTheme.accent)

                            Text(viewModel.selectedItem == nil
                                 ? "Seleccionar video"
                                 : "Cambiar video")
                                .fontWeight(.medium)
                                .foregroundStyle(viewModel.selectedItem == nil
                                                 ? BCTheme.textSecondary
                                                 : BCTheme.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(BCTheme.textTertiary)
                        }
                        .padding(16)
                        .background(BCTheme.cardGray)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(viewModel.selectedItem == nil
                                        ? BCTheme.borderGray
                                        : BCTheme.accent.opacity(0.5),
                                        lineWidth: 1)
                        )
                    }
                    .onChange(of: viewModel.selectedItem) { _, newItem in
                        guard let newItem else {
                            previewPlayer = nil
                            previewURL    = nil
                            return
                        }
                        // Carga la vista previa
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                let tempURL = FileManager.default.temporaryDirectory
                                    .appendingPathComponent("preview_\(UUID().uuidString).mp4")
                                try? data.write(to: tempURL)
                                await MainActor.run {
                                    previewURL    = tempURL
                                    previewPlayer = AVPlayer(url: tempURL)
                                    haptic.impactOccurred()
                                }
                            }
                        }
                    }

                    // MARK: - Campos
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre del video")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(BCTheme.textSecondary)
                            TextField("ej. Mi video de presentación", text: $viewModel.videoName)
                                .bcField()
                                .focused($focusedField, equals: .name)
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descripción (opcional)")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(BCTheme.textSecondary)
                            TextEditor(text: $viewModel.videoDescription)
                                .frame(height: 80)
                                .bcField()
                                .focused($focusedField, equals: .description)
                        }
                    }

                    // MARK: - Estado / Progreso
                    if viewModel.uploadState != .idle {
                        VStack(spacing: 12) {
                            if viewModel.uploadState == .uploading {
                                VStack(spacing: 8) {
                                    ProgressView(value: viewModel.uploadProgress)
                                        .tint(BCTheme.accent)
                                    Text("\(Int(viewModel.uploadProgress * 100))%")
                                        .font(.footnote)
                                        .foregroundStyle(BCTheme.textSecondary)
                                }
                            } else if viewModel.uploadState == .preparing ||
                                      viewModel.uploadState == .processing {
                                HStack(spacing: 10) {
                                    ProgressView().tint(BCTheme.accent)
                                    Text(viewModel.stateMessage)
                                        .font(.footnote)
                                        .foregroundStyle(BCTheme.textSecondary)
                                }
                            } else if viewModel.uploadState == .done {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(BCTheme.accent)
                                    Text(viewModel.stateMessage)
                                        .font(.footnote)
                                        .foregroundStyle(BCTheme.accent)
                                }
                                .onAppear { haptic.impactOccurred() }
                            } else if viewModel.uploadState == .failed {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(viewModel.stateMessage)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(16)
                        .background(BCTheme.cardGray)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // MARK: - Botón subir
                    Button {
                        focusedField = nil
                        haptic.impactOccurred()
                        Task { await viewModel.upload() }
                    } label: {
                        ZStack {
                            if viewModel.uploadState == .uploading ||
                               viewModel.uploadState == .preparing ||
                               viewModel.uploadState == .processing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Subir video")
                            }
                        }
                        .bcButton()
                    }
                    .disabled(
                        viewModel.selectedItem == nil ||
                        viewModel.videoName.isEmpty ||
                        viewModel.uploadState == .uploading ||
                        viewModel.uploadState == .preparing ||
                        viewModel.uploadState == .processing
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onDisappear {
            previewPlayer?.pause()
            previewPlayer = nil
            if let url = previewURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

#Preview {
    UploadView()
}

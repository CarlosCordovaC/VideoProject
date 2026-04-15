//
//  SearchView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 13/04/26.
//

//  SearchView.swift
//  BrightcoveProject

import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: VideoViewModel
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) var dismiss

    @State private var query = ""
    @State private var searchTask: Task<Void, Never>? = nil
    @FocusState private var isSearchFocused: Bool

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            BCTheme.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Header
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(BCTheme.textPrimary)
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(BCTheme.textSecondary)
                            .font(.system(size: 15))

                        TextField("Buscar videos...", text: $query)
                            .foregroundStyle(BCTheme.textPrimary)
                            .tint(BCTheme.accent)
                            .autocorrectionDisabled()
                            .focused($isSearchFocused)
                            .onChange(of: query) { _, newValue in
                                // Debounce — espera 0.4s después de que el usuario deja de escribir
                                searchTask?.cancel()
                                searchTask = Task {
                                    try? await Task.sleep(nanoseconds: 400_000_000)
                                    guard !Task.isCancelled else { return }
                                    await viewModel.searchVideos(query: newValue)
                                }
                            }

                        if !query.isEmpty {
                            Button {
                                query = ""
                                viewModel.searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(BCTheme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(BCTheme.cardGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BCTheme.borderGray, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .background(BCTheme.borderGray)

                // MARK: - Contenido
                ScrollView {
                    if viewModel.isSearching {
                        VStack {
                            Spacer(minLength: 80)
                            ProgressView()
                                .tint(BCTheme.accent)
                                .scaleEffect(1.2)
                            Text("Buscando...")
                                .font(.footnote)
                                .foregroundStyle(BCTheme.textSecondary)
                                .padding(.top, 12)
                        }
                        .frame(maxWidth: .infinity)

                    } else if query.isEmpty {
                        VStack(spacing: 12) {
                            Spacer(minLength: 80)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(BCTheme.textTertiary)
                            Text("Escribe para buscar videos")
                                .font(.subheadline)
                                .foregroundStyle(BCTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)

                    } else if viewModel.searchResults.isEmpty {
                        VStack(spacing: 12) {
                            Spacer(minLength: 80)
                            Image(systemName: "video.slash")
                                .font(.system(size: 48))
                                .foregroundStyle(BCTheme.textTertiary)
                            Text("Sin resultados para \"\(query)\"")
                                .font(.subheadline)
                                .foregroundStyle(BCTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)

                    } else {
                        // MARK: - Grid de resultados
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.searchResults) { video in
                                Button {
                                    navigationPath.append(video)
                                    dismiss()
                                } label: {
                                    VideoGridCell(video: video)
                                }
                            }
                        }
                        .padding(16)

                        Text("\(viewModel.searchResults.count) resultado\(viewModel.searchResults.count == 1 ? "" : "s")")
                            .font(.footnote)
                            .foregroundStyle(BCTheme.textSecondary)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
        .onDisappear {
            viewModel.searchResults = []
        }
    }
}

// MARK: - Celda del grid
private struct VideoGridCell: View {
    let video: Video

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(BCTheme.cardGray)
                    .aspectRatio(16/9, contentMode: .fit)

                if let thumb = video.thumbnailURL, let url = URL(string: thumb) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .tint(BCTheme.accent)
                    }
                    .aspectRatio(16/9, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "video.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(BCTheme.textTertiary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(BCTheme.borderGray, lineWidth: 0.5)
            )

            // Nombre
            Text(video.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(BCTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    SearchView(
        viewModel: VideoViewModel(),
        navigationPath: .constant(NavigationPath())
    )
}

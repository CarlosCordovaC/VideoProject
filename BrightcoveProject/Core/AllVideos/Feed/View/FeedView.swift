//  FeedView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 02/08/25.
//

//  FeedView.swift
//  BrightcoveProject

import SwiftUI

struct FeedView: View {
    @StateObject var viewModel = VideoViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var showSearch = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {

                // MARK: - Feed
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.videos) { video in
                            FeedCell(
                                video: video,
                                navigationPath: $navigationPath,
                                viewModel: viewModel
                            )
                            .frame(height: UIScreen.main.bounds.height)
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea()
                .onReceive(NotificationCenter.default.publisher(for: .videoUploaded)) { _ in
                    Task { await viewModel.loadVideos() }
                }

                // MARK: - Barra de búsqueda flotante
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.system(size: 15))

                        Text("Buscar videos...")
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.system(size: 15))

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 55)
                    .onTapGesture {
                        showSearch = true
                    }

                    Spacer()
                }
            }
            .navigationDestination(for: Video.self) { video in
                VideoInfoView(
                    video: video,
                    viewModel: viewModel,
                    navigationPath: $navigationPath
                )
                .navigationBarBackButtonHidden()
            }
            .fullScreenCover(isPresented: $showSearch) {
                SearchView(
                    viewModel: viewModel,
                    navigationPath: $navigationPath
                )
            }
        }
    }
}

#Preview {
    FeedView()
}

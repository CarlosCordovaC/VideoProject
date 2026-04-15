//
//  VideoInfoView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 20/07/25.
//

import SwiftUI
import AVKit

struct VideoInfoView: View {
    
    let video: Video
        @ObservedObject var viewModel: VideoViewModel
        @Binding var navigationPath: NavigationPath
        
        @State private var thumbnailURL: String? = nil
        @State private var showToast = false
        @State private var toastMessage = ""
        @Environment(\.dismiss) var dismiss


    
    var body: some View {
            VStack{
                ScrollView{
                    
                    VStack(alignment: .leading, spacing: 12){
                        
                        // Back Button
                        Button(){
                            dismiss()
                        }label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(.gray))
                        }
                        .padding()
                        
                        // MARK: - Preview block (thumbnail or video_preview)
                        Group {
                            if let urlString = viewModel.videoURL(for: video.id),
                               let url = URL(string: urlString) {
                                VideoPlayerWithControls(url: url)
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundStyle(BCTheme.cardGray)
                                        .frame(height: 220)
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .tint(BCTheme.accent)
                                        Text("Cargando preview...")
                                            .font(.footnote)
                                            .foregroundStyle(BCTheme.textSecondary)
                                    }
                                }
                            }
                        }
                        .onChange(of: viewModel.videoURL(for: video.id)) { _, _ in }

                        
                        //Name and Status
                        VStack(alignment: .leading, spacing: 25){
                            HStack(){
                                Text("Name:")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(video.name)
                                
                                Spacer()
                                
                                if video.state == "ACTIVE"{
                                    Text(video.state)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color(.white))
                                        .frame(width: 120, height: 30)
                                        .background(Color(.green))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay{
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(lineWidth: 2)
                                                .foregroundStyle(.black)
                                        }
                                }
                                    
                                else{
                                    Text(video.state)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color(.white))
                                        .frame(width: 120, height: 30)
                                        .background(Color(.red))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay{
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(lineWidth: 2)
                                                .foregroundStyle(.black)
                                        }
                                }
                            }
                            
                            HStack(){
                                
                                Text("Original Name: Test Video2")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(.gray))
                                
                                Spacer()
                                
                                // Busca el NavigationLink del botón de editar y reemplázalo:
                                NavigationLink {
                                    EditInfoVideoView(
                                        video: video,
                                        viewModel: viewModel,
                                        navigationPath: $navigationPath
                                    )
                                    .navigationBarBackButtonHidden()
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundStyle(Color(.gray))
                                }
                                
                            }
                            
                        }
                        .padding()
                        
                        Divider()
                        
                        //Video Information
                        VStack(alignment: .leading, spacing: 8){
                            Text("Video Information")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack(){
                                Text("ID:")
                                    .fontWeight(.semibold)
                                Text(video.id)
                            }
                            .font(.subheadline)
                            
                            HStack(){
                                Text("Account ID:")
                                    .fontWeight(.semibold)
                                Text(video.accountId)
                            }
                            .font(.subheadline)
                            
                            HStack(){
                                Text("Created At:")
                                    .fontWeight(.semibold)
                                Text(video.createdAt)
                            }
                            .font(.subheadline)
                        }
                        .padding()
                        
                        Divider()
                        
                        //Created By
                        VStack(alignment: .leading, spacing: 8){
                            Text("Created By")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack(){
                                Text("Type:")
                                    .fontWeight(.semibold)
                                Text(video.createdBy.type)
                                
                                Text("ID:")
                                    .fontWeight(.semibold)
                                Text(video.createdBy.id ?? "N/A")
                            }
                            HStack(){
                                Text("Email: ")
                                    .fontWeight(.semibold)
                                Text(video.createdBy.email ?? "N/A")
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        //Video Files
                        VStack(alignment: .leading, spacing:8){
                            Text("Video Files")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack(){
                                Text("Source File Name:")
                                    .fontWeight(.semibold)
                                Text("Test: Add_avatar")
                                
                            }
                           
                            HStack(){
                                Text("Ingestion Profile:")
                                    .fontWeight(.semibold)
                                Text("Test: multi-platform-standard-static")
                                    .font(.footnote)
                            }
                            
                            
                        }
                        .padding()
                        
                        //Tags
                        /*
                        VStack(alignment: .leading, spacing: 8){
                            Text("Tags")
                                .font(.title2)
                                .fontWeight(.semibold)
                            if video.tags == []{
                                Text("No hay informacion")
                                    .font(.footnote)
                            }else{
                                TagsScrollView(tags: video.tags)
                            }
                        }
                        .padding()
                         */
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8){
                            Text("Images")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if let thumbnailURL = thumbnailURL, let url = URL(string: thumbnailURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipped()
                                } placeholder: {
                                    Rectangle()
                                        .foregroundStyle(.gray.opacity(0.2))
                                        .overlay(ProgressView())
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                
                            }
                            //No image view
                            else {
                                Rectangle()
                                    .foregroundStyle(.gray.opacity(0.1))
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        Text("Sin imagen")
                                            .foregroundStyle(.gray)
                                    )
                            }
                        }
                        .padding()
                        
                        //Short Description
                        /*
                        VStack(alignment: .leading, spacing: 20){
                            HStack(){
                                Text("Short Description")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Spacer()
                                
                                NavigationLink(){
                                    EditInfoVideoView()
                                        .navigationBarBackButtonHidden()
                                    
                                }label:{
                                    Image(systemName: "square.and.pencil")
                                        .foregroundStyle(Color(.gray))
                                }
                                
                            }
                            .padding(.leading, 0)
                            
                            Text(video.description ?? "No description in the video")
                                .font(.footnote)
                            
                            Button(){
                                
                                print("TEST Long Description")
                                
                            }label: {
                                HStack(spacing:5){
                                    Text("Long Description ")
                                        .font(.caption2)
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundStyle(Color(.gray))
                            }
                        }
                        .padding()
                        .frame(width: 350, height: 220)
                        .overlay{
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(lineWidth: 1)
                            
                        }
                        .padding()
                         */
                        
                        // Delete Button
                        /*
                        VStack(alignment: .leading){
                            buttonView(name: "Delete Video", color: .red) {
                                viewModel.deleteVideo(video: video)
                                toastMessage = "Video eliminado exitosamente"
                                showToast = true
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showToast = false
                                    navigationPath.removeLast()
                                }
                            }
                            
                        }
                        .padding()
                         */
                    }
                }
            }
            .onAppear {
                Task {
                    // Carga source y thumbnail en paralelo
                    async let source    = viewModel.loadSourceIfNeeded(for: video.id)
                    async let thumbnail = viewModel.fetchThumbnail(for: video)
                    
                    let (_, thumb) = await (source, thumbnail)
                    thumbnailURL = thumb
                }
            }
            .overlay(
                Group {
                    if showToast {
                        ToastView(toastMessage: $toastMessage, showToast: $showToast)
                    }
                }
            )
            
        }
    }

// MARK: - Player con play manual
private struct VideoPlayerWithControls: View {
    let url: URL
    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
            } else {
                Rectangle()
                    .foregroundStyle(.black)
            }

            // Botón play (solo cuando está pausado)
            if !isPlaying {
                Button {
                    if player == nil {
                        player = AVPlayer(url: url)
                    }
                    player?.play()
                    isPlaying = true
                } label: {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(radius: 4)
                }
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
            isPlaying = false
        }
    }
}


#Preview {
    let dummyVideo = Video(
        id: "1",
        accountId: "12331231",
        name: "Video de ejemplo",
        createdAt: "2025",
        state: "ACTIVE",
        createdBy: CreatedBy(type: "User", id: "123", email: "ejemplo@correo.com"),
        description: "Ejemplo Description",
        tags: ["TEST"]
    )

    let dummyViewModel = VideoViewModel()
    let dummyNavigationPath = Binding.constant(NavigationPath())

    return VideoInfoView(video: dummyVideo, viewModel: dummyViewModel, navigationPath: dummyNavigationPath)
}


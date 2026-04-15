//
//  ContentView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 13/06/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = VideoViewModel()
    @State private var thumbnailURL: String? = nil
    @State private var navigationPath = NavigationPath()

    
    var body: some View {
        
        NavigationStack(path: $navigationPath) {
            VStack {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                //Video List
                else {
                    List(viewModel.videos) { video in
                        NavigationLink(value: video) {
                            VStack(alignment: .leading) {
                                HStack(spacing: 12){
                                    
                                    Image(systemName: "video")
                                    Text(video.name)
                                        .font(.headline)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .padding()
    
            //Video Info
            .navigationDestination(for: Video.self){video in
                VideoInfoView(video: video,
                              viewModel: viewModel,
                              navigationPath: $navigationPath)
                .navigationBarBackButtonHidden()
            }
            
        }
    }
}


#Preview {
    ContentView()
}


//
//  FeedViewModel.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 04/08/25.
//

import Foundation

class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []

    func generatePosts(from videos: [Video]) {
        self.posts = videos.compactMap { video in
            if let url = video.videoURL {
                return Post(id: video.id, videoUrl: url)
            } else {
                return nil
            }
        }
    }
}

//
//  FeedVideoPlayer.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 17/11/25.
//

import Foundation
import AVKit

class FeedVideoPlayer: ObservableObject {
    @Published var player: AVPlayer
    
    init(url: String) {
        self.player = AVPlayer(url: URL(string: url)!)
    }
}


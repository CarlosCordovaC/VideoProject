//
//  BrightcoveProjectApp.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 13/06/25.
//

import SwiftUI

@main
struct BrightcoveProjectApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn {
                MainTabView(authViewModel: authViewModel)
            } else {
                SplashView(authViewModel: authViewModel)
            }
        }
    }
}

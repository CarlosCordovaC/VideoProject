//
//  SplashView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 31/03/26.
//

//  SplashView.swift
//  BrightcoveProject

import SwiftUI

struct SplashView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var isActive = false
    @State private var opacity  = 0.0
    @State private var scale    = 0.85

    var body: some View {
        if isActive {
            LoginView(authViewModel: authViewModel)
        } else {
            ZStack {
                BCTheme.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(BCTheme.accent.opacity(0.15))
                            .frame(width: 160, height: 160)
                        Circle()
                            .fill(BCTheme.accent.opacity(0.08))
                            .frame(width: 200, height: 200)
                        Image(systemName: "play.rectangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundStyle(BCTheme.accent)
                    }

                    VStack(spacing: 6) {
                        Text("Brightcove")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(BCTheme.textPrimary)

                        Text("VIDEO CLOUD")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BCTheme.accent)
                            .tracking(4)
                    }
                }
                .opacity(opacity)
                .scaleEffect(scale)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    opacity = 1.0
                    scale   = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView(authViewModel: AuthViewModel())
}

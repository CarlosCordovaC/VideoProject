//
//  MainTabView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 18/07/25.
//

//  MainTabView.swift
//  BrightcoveProject

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            FeedView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .onAppear { selectedTab = 0 }
                .tag(0)

            Text("Friends")
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "person.2.fill" : "person.2")
                    Text("Friends")
                }
                .onAppear { selectedTab = 1 }
                .tag(1)

            UploadView()
                .tabItem {
                    Image(systemName: "plus")
                }
                .tag(2)

            Text("Notifications")
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "heart.fill" : "heart")
                    Text("Inbox")
                }
                .onAppear { selectedTab = 3 }
                .tag(3)

            ProfileView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                    Text("Profile")
                }
                .onAppear { selectedTab = 4 }
                .tag(4)
        }
        .tint(.black)
    }
}

#Preview {
    MainTabView(authViewModel: AuthViewModel())
}

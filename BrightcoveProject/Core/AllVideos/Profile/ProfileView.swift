//
//  ProfileView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 18/07/25.
//


//  ProfileView.swift
//  BrightcoveProject

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel

    private var accountId: String { KeychainManager.read(key: "bc_account_id") ?? "—" }
    private var clientId:  String { KeychainManager.read(key: "bc_client_id")  ?? "—" }

    var body: some View {
        ZStack {
            BCTheme.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Avatar
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(BCTheme.cardGray)
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Circle().stroke(BCTheme.accent, lineWidth: 2)
                                )
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(BCTheme.accent)
                        }
                        .padding(.top, 32)

                        Text("Mi cuenta")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(BCTheme.textPrimary)
                    }

                    // MARK: - Info card
                    VStack(spacing: 0) {
                        infoRow(label: "Account ID", value: accountId)
                        Divider().background(BCTheme.borderGray)
                        infoRow(label: "Client ID", value: String(clientId.prefix(24)) + "...")
                    }
                    .background(BCTheme.cardGray)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(BCTheme.borderGray, lineWidth: 1)
                    )

                    // MARK: - Cerrar sesión
                    Button {
                        authViewModel.logout()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Cerrar sesión")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(BCTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.footnote)
                .foregroundStyle(BCTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    ProfileView(authViewModel: AuthViewModel())
}

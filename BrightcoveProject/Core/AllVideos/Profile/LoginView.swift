//
//  Login.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 15/07/25.
//

//  LoginView.swift
//  BrightcoveProject

import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel

    @State private var clientId     = ""
    @State private var clientSecret = ""
    @State private var accountId    = ""
    @FocusState private var focusedField: Field?

    enum Field { case clientId, clientSecret, accountId }

    var body: some View {
        ZStack {
            BCTheme.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 36) {

                    // MARK: - Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(BCTheme.accent.opacity(0.15))
                                .frame(width: 90, height: 90)
                            Image(systemName: "play.rectangle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .foregroundStyle(BCTheme.accent)
                        }
                        .padding(.top, 60)

                        Text("Brightcove")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(BCTheme.textPrimary)

                        Text("Ingresa las credenciales de tu cuenta")
                            .font(.subheadline)
                            .foregroundStyle(BCTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // MARK: - Campos
                    VStack(spacing: 20) {
                        credentialField(
                            title: "Account ID",
                            placeholder: "ej. 6415901434001",
                            text: $accountId,
                            isSecure: false,
                            field: .accountId
                        )
                        credentialField(
                            title: "Client ID",
                            placeholder: "ej. 5b38ef71-cbd8-...",
                            text: $clientId,
                            isSecure: false,
                            field: .clientId
                        )
                        credentialField(
                            title: "Client Secret",
                            placeholder: "Tu client secret",
                            text: $clientSecret,
                            isSecure: true,
                            field: .clientSecret
                        )
                    }

                    // MARK: - Error
                    if let error = authViewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // MARK: - Botón
                    Button {
                        focusedField = nil
                        Task {
                            await authViewModel.login(
                                clientId: clientId,
                                clientSecret: clientSecret,
                                accountId: accountId
                            )
                        }
                    } label: {
                        ZStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Iniciar sesión")
                            }
                        }
                        .bcButton()
                    }
                    .disabled(authViewModel.isLoading)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func credentialField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(BCTheme.textSecondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .bcField()
            .focused($focusedField, equals: field)
        }
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
}

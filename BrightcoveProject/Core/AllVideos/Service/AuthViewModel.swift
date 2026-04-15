//
//  AuthViewModel.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 31/03/26.
//

import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Valida las credenciales intentando obtener un token real
    func login(clientId: String, clientSecret: String, accountId: String) async {
        guard !clientId.isEmpty, !clientSecret.isEmpty, !accountId.isEmpty else {
            errorMessage = "Todos los campos son requeridos"
            return
        }

        isLoading = true
        errorMessage = nil

        let credentials = "\(clientId):\(clientSecret)"
        guard let credData = credentials.data(using: .utf8) else {
            errorMessage = "Credenciales inválidas"
            isLoading = false
            return
        }

        var request = URLRequest(url: URL(string: "https://oauth.brightcove.com/v4/access_token")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(credData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                errorMessage = "Respuesta inválida del servidor"
                isLoading = false
                return
            }

            guard http.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["access_token"] as? String != nil else {
                errorMessage = "Credenciales incorrectas. Verifica tu Client ID y Client Secret."
                isLoading = false
                return
            }

            // Credenciales válidas — guardar en Keychain
            KeychainManager.save(key: "bc_client_id",     value: clientId)
            KeychainManager.save(key: "bc_client_secret", value: clientSecret)
            KeychainManager.save(key: "bc_account_id",    value: accountId)

            isLoggedIn = true

        } catch {
            errorMessage = "Error de conexión: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func logout() {
        KeychainManager.deleteAll()
        isLoggedIn = false
    }
}

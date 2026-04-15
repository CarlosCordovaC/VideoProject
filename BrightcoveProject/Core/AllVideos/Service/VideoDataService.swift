//  VideoDataService.swift
//  BrightcoveProject

import Foundation

class VideoDataService {
    private var clientId: String {
            KeychainManager.read(key: "bc_client_id") ?? ""
        }
        private var clientSecret: String {
            KeychainManager.read(key: "bc_client_secret") ?? ""
        }
        private var accountId: String {
            KeychainManager.read(key: "bc_account_id") ?? ""
        }

    // MARK: - Token
    func fetchAccessToken() async -> String? {
        let credentials = "\(clientId):\(clientSecret)"
        guard let credData = credentials.data(using: .utf8) else { return nil }
        let base64 = credData.base64EncodedString()

        var request = URLRequest(url: URL(string: "https://oauth.brightcove.com/v4/access_token")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else { return nil }
        return token
    }

    // MARK: - Videos
    func fetchVideos(token: String, offset: Int = 0, limit: Int = 20) async throws -> [Video] {
        let url = URL(string: "https://cms.api.brightcove.com/v1/accounts/\(accountId)/videos?limit=\(limit)&offset=\(offset)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        // Log temporal
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🌐 URL llamada: \(url)")
            print("📄 Respuesta cruda (primeros 500 chars): \(String(jsonString.prefix(500)))")
        }
        
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NSError(domain: "", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No se pudo parsear videos"])
        }

        let videos = jsonArray.compactMap { item -> Video? in
            guard let id        = item["id"]         as? String,
                  let accountId = item["account_id"] as? String,
                  let name      = item["name"]        as? String,
                  let createdAt = item["created_at"]  as? String,
                  let state     = item["state"]        as? String,
                  let cbDict    = item["created_by"]  as? [String: Any],
                  let type      = cbDict["type"]       as? String else { return nil }

            let createdBy = CreatedBy(
                type: type,
                id: cbDict["id"] as? String,         // opcional, puede ser nil
                email: cbDict["email"] as? String    // opcional, puede ser nil
            )

            return Video(
                id: id, accountId: accountId, name: name,
                createdAt: createdAt, state: state, createdBy: createdBy,
                description: item["description"] as? String,
                longDescription: item["long_description"] as? String,  // ← agrega esta línea
                tags: item["tags"] as? [String] ?? []
            )
        }

        print("✅ Videos parseados: \(videos.count) de \(jsonArray.count)")
        return videos
    }

    // MARK: - Sources (URL del video)
    func fetchVideoSources(videoID: String, token: String) async -> String? {
        let urlString = "https://cms.api.brightcove.com/v1/accounts/\(accountId)/videos/\(videoID)/sources"
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let jsonArray  = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              jsonArray.count >= 2 else { return nil }

        return jsonArray[1]["src"] as? String
    }

    // MARK: - Thumbnail
    func fetchVideoThumbnail(videoID: String, token: String) async -> String? {
        let urlString = "https://cms.api.brightcove.com/v1/accounts/\(accountId)/videos/\(videoID)/images"
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json       = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let poster     = json["poster"] as? [String: Any],
              let src        = poster["src"] as? String else { return nil }
        return src
    }

    // MARK: - Delete
    func deleteVideo(videoID: String, token: String) async throws {
        let urlString = "https://cms.api.brightcove.com/v1/accounts/\(accountId)/videos/\(videoID)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 204 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "", code: code,
                          userInfo: [NSLocalizedDescriptionKey: "Error al eliminar video"])
        }
    }
    
    func updateVideo(videoID: String, token: String,
                     name: String,
                     description: String?,
                     longDescription: String?) async throws {

        let accountId = KeychainManager.read(key: "bc_account_id") ?? ""
        let urlString = "https://cms.api.brightcove.com/v1/accounts/\(accountId)/videos/\(videoID)"
        guard let url = URL(string: urlString) else { return }

        var body: [String: Any] = ["name": name]
        body["description"]      = description      ?? NSNull()
        body["long_description"] = longDescription  ?? NSNull()

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "", code: code,
                          userInfo: [NSLocalizedDescriptionKey: "Error al actualizar video (código \(code))"])
        }
    }
    
    func fetchIngestProfiles(token: String) async -> [String] {
        let accountId = KeychainManager.read(key: "bc_account_id") ?? ""
        let urlString = "https://ingest.api.brightcove.com/v1/accounts/\(accountId)/profiles"
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            print("❌ Error de conexión")
            return []
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let responseString = String(data: data, encoding: .utf8) ?? "sin respuesta"
        print("📥 Status: \(statusCode)")
        print("📥 Respuesta: \(responseString.prefix(500))")

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return json.compactMap { $0["name"] as? String }
    }
    
    // MARK: - Search videos
    func searchVideos(query: String, token: String) async throws -> [Video] {
        let accountId = KeychainManager.read(key: "bc_account_id") ?? ""
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://cms.api.brightcove.com/v1/accounts/\(accountId)/videos?q=\(encodedQuery)&limit=20"
        guard let url = URL(string: urlString) else { throw NSError(domain: "", code: -1) }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NSError(domain: "", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No se pudo parsear resultados"])
        }

        return jsonArray.compactMap { item -> Video? in
            guard let id        = item["id"]         as? String,
                  let accountId = item["account_id"] as? String,
                  let name      = item["name"]        as? String,
                  let createdAt = item["created_at"]  as? String,
                  let state     = item["state"]        as? String,
                  let cbDict    = item["created_by"]  as? [String: Any],
                  let type      = cbDict["type"]       as? String else { return nil }

            let createdBy = CreatedBy(
                type: type,
                id: cbDict["id"] as? String,
                email: cbDict["email"] as? String
            )

            // Extraer thumbnail
            var thumbnailURL: String? = nil
            if let images = item["images"] as? [String: Any],
               let poster = images["thumbnail"] as? [String: Any],
               let src    = poster["src"] as? String {
                thumbnailURL = src
            }

            return Video(
                id: id, accountId: accountId, name: name,
                createdAt: createdAt, state: state, createdBy: createdBy,
                description: item["description"] as? String,
                longDescription: item["long_description"] as? String,
                thumbnailURL: thumbnailURL,
                tags: item["tags"] as? [String] ?? []
            )
        }
    }
}

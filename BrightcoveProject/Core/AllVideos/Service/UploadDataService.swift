//
//  UploadDataService.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 01/04/26.
//

import Foundation

class UploadDataService {
    private var accountId: String { KeychainManager.read(key: "bc_account_id") ?? "" }

    // MARK: - Paso 1: Crear video vacío en CMS
    func createVideo(name: String, description: String?, token: String) async throws -> String {
        let url = URL(string: "https://cms.api.brightcove.com/v1/accounts/\(accountId)/videos")!
        var body: [String: Any] = ["name": name]
        if let desc = description { body["description"] = desc }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 201,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let videoId = json["id"] as? String else {
            throw UploadError.failedToCreateVideo
        }
        return videoId
    }

    // MARK: - Paso 2: Obtener URL de S3
    func getUploadURL(videoId: String, filename: String, token: String) async throws -> (signedURL: String, apiRequestURL: String) {
        let urlString = "https://ingest.api.brightcove.com/v1/accounts/\(accountId)/videos/\(videoId)/upload-urls/\(filename)"
        guard let url = URL(string: urlString) else { throw UploadError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log para ver exactamente qué regresa Brightcove
        if let json = String(data: data, encoding: .utf8) {
            print("📥 Upload URL response: \(json)")
        }
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let signedURL     = json["signed_url"]      as? String,
              let apiRequestURL = json["api_request_url"] as? String else {
            throw UploadError.failedToGetUploadURL
        }
        return (signedURL, apiRequestURL)
    }

    // MARK: - Paso 3: Subir archivo a S3
    func uploadToS3(fileData: Data, uploadURL: String, mimeType: String, progressHandler: @escaping (Double) -> Void) async throws {
        guard let url = URL(string: uploadURL) else { throw UploadError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(fileData.count)", forHTTPHeaderField: "Content-Length")

        let delegate = UploadProgressDelegate(progressHandler: progressHandler)
        let session  = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

        let (_, response) = try await session.upload(for: request, from: fileData)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UploadError.failedToUploadToS3
        }
    }

    // MARK: - Paso 4: Notificar a Brightcove que ingeste el video
    // MARK: - Paso 4: Notificar a Brightcove que ingeste el video
    func ingestVideo(videoId: String, uploadURL: String, token: String) async throws {
        let url = URL(string: "https://ingest.api.brightcove.com/v1/accounts/\(accountId)/videos/\(videoId)/ingest-requests")!
        let body: [String: Any] = [
            "master": ["url": uploadURL],     // ← usa la signed_url directamente
            "profile": "multi-platform-standard-static",
            "capture-images": true
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Ingest response: \(responseString)")
        }
        
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 201 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw UploadError.failedToIngest
        }
    }
}

// MARK: - Errores
enum UploadError: LocalizedError {
    case failedToCreateVideo
    case failedToGetUploadURL
    case failedToUploadToS3
    case failedToIngest
    case invalidURL
    case noFileSelected

    var errorDescription: String? {
        switch self {
        case .failedToCreateVideo:   return "No se pudo crear el video en Brightcove"
        case .failedToGetUploadURL:  return "No se pudo obtener la URL de subida"
        case .failedToUploadToS3:    return "Error al subir el archivo"
        case .failedToIngest:        return "Error al procesar el video en Brightcove"
        case .invalidURL:            return "URL inválida"
        case .noFileSelected:        return "No se seleccionó ningún archivo"
        }
    }
}

// MARK: - Delegate para progreso de subida
class UploadProgressDelegate: NSObject, URLSessionTaskDelegate {
    let progressHandler: (Double) -> Void

    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            self.progressHandler(progress)
        }
    }
}

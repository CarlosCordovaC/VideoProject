//
//  UploadViewModel.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 01/04/26.
//

import Foundation
import PhotosUI
import SwiftUI

@MainActor
class UploadViewModel: ObservableObject {
    @Published var videoName        = ""
    @Published var videoDescription = ""
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var uploadProgress: Double = 0
    @Published var uploadState: UploadState = .idle
    @Published var errorMessage: String?

    private let service     = UploadDataService()
    private let videoService = VideoDataService()

    enum UploadState {
        case idle
        case preparing
        case uploading
        case processing
        case done
        case failed
    }

    var stateMessage: String {
        switch uploadState {
        case .idle:       return ""
        case .preparing:  return "Preparando video..."
        case .uploading:  return "Subiendo a Brightcove..."
        case .processing: return "Procesando en Brightcove..."
        case .done:       return "¡Video subido exitosamente!"
        case .failed:     return errorMessage ?? "Error desconocido"
        }
    }

    func upload() async {
        guard !videoName.isEmpty else {
            errorMessage = "El nombre del video es requerido"
            return
        }
        guard let item = selectedItem else {
            errorMessage = "Selecciona un video primero"
            return
        }

        uploadState = .preparing
        errorMessage = nil

        do {
            // Obtener token
            guard let token = await videoService.fetchAccessToken() else {
                throw UploadError.failedToCreateVideo
            }

            // Cargar datos del video seleccionado
            guard let videoData = try await item.loadTransferable(type: Data.self) else {
                throw UploadError.noFileSelected
            }

            let filename = "\(videoName.replacingOccurrences(of: " ", with: "_")).mp4"

            // Paso 1: Crear video
            uploadState = .preparing
            let videoId = try await service.createVideo(
                name: videoName,
                description: videoDescription.isEmpty ? nil : videoDescription,
                token: token
            )
            print("✅ Video creado: \(videoId)")

            // Paso 2: Obtener URL de S3
            let (signedURL, apiRequestURL) = try await service.getUploadURL(
                videoId: videoId,
                filename: filename,
                token: token
            )
            print("✅ URL de subida obtenida")
            print("📤 signedURL: \(signedURL)")
            print("📤 apiRequestURL: \(apiRequestURL)")

            // Paso 3: Subir a S3 — usa signedURL (PUT)
            uploadState = .uploading
            try await service.uploadToS3(
                fileData: videoData,
                uploadURL: signedURL,
                mimeType: "video/mp4"
            ) { progress in
                self.uploadProgress = progress
            }
            print("✅ Video subido a S3")

            // Paso 4: Ingestar — usa apiRequestURL (GET para Zencoder)
            uploadState = .processing
            try await service.ingestVideo(
                videoId: videoId,
                uploadURL: apiRequestURL,
                token: token
            )
            print("✅ Ingest iniciado")

            uploadState = .done
            NotificationCenter.default.post(name: .videoUploaded, object: nil)
            reset()

        } catch {
            uploadState   = .failed
            errorMessage  = error.localizedDescription
        }
    }

    func reset() {
        videoName        = ""
        videoDescription = ""
        selectedItem     = nil
        uploadProgress   = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.uploadState = .idle
        }
    }
    
    init() {
        Task {
            print("🔄 Iniciando fetch de perfiles...")
            guard let token = await videoService.fetchAccessToken() else {
                print("❌ No se pudo obtener token")
                return
            }
            print("✅ Token obtenido: \(token.prefix(20))...")
            let profiles = await videoService.fetchIngestProfiles(token: token)
            print("📋 Perfiles count: \(profiles.count)")
        }
    }
}

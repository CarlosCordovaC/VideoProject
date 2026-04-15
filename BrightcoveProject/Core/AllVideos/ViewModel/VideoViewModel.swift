//  VideoViewModel.swift
//  BrightcoveProject

import Foundation

@MainActor
class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [Video] = []
    @Published var isSearching = false

    private let service = VideoDataService()
    private var cachedToken: String?          // Token cacheado
    private var loadingSourceIDs: Set<String> = [] // Evita duplicados

    init() {
        Task { await loadVideos() }
    }
    
    func videoURL(for id: String) -> String? {
        videos.first(where: { $0.id == id })?.videoURL
    }

    // MARK: - Token (cacheado)
    func getToken() async -> String? {
        if let token = cachedToken { return token }
        let token = await service.fetchAccessToken()
        cachedToken = token
        return token
    }

    // MARK: - Cargar lista de videos (sin sources todavía)
    // MARK: - Cargar lista de videos con paginación
    func loadVideos() async {
        isLoading = true
        defer { isLoading = false }

        guard let token = await getToken() else {
            errorMessage = "No se pudo obtener el token"
            return
        }

        do {
            var allVideos: [Video] = []
            var offset = 0
            let limit = 20

            // Pagina hasta traer todos los videos
            while true {
                let batch = try await service.fetchVideos(token: token, offset: offset, limit: limit)
                print("📦 Batch offset \(offset): \(batch.count) videos")
                allVideos.append(contentsOf: batch)
                
                if batch.count < limit {
                    print("✅ Última página. Total: \(allVideos.count)")
                    break
                }
                offset += limit
            }

            self.videos = allVideos
            print("✅ Total videos cargados: \(allVideos.count)")
            
            // Solo precarga los primeros 5 sources
            await loadInitialSources(token: token)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Carga los primeros N sources al inicio
    private func loadInitialSources(token: String) async {
        let initialBatch = videos.prefix(5)
        await withTaskGroup(of: Void.self) { group in
            for video in initialBatch {
                group.addTask {
                    await self.loadSourceForVideo(id: video.id, token: token)
                }
            }
        }
    }

    // MARK: - Carga el source de UN video (llamado bajo demanda desde FeedCell)
    func loadSourceIfNeeded(for videoID: String) async {
        print("🔍 loadSourceIfNeeded llamado para: \(videoID)")
        
        guard !loadingSourceIDs.contains(videoID) else {
            print("⏳ Ya está cargando: \(videoID)")
            return
        }
        guard let index = videos.firstIndex(where: { $0.id == videoID }) else {
            print("❌ No encontré el video en el array: \(videoID)")
            return
        }
        guard videos[index].videoURL == nil else {
            print("✅ Ya tiene URL: \(videoID)")
            return
        }

        print("📡 Pidiendo source para: \(videoID)")
        guard let token = await getToken() else {
            print("❌ No hay token")
            return
        }
        
        loadingSourceIDs.insert(videoID)
        await loadSourceForVideo(id: videoID, token: token)
        loadingSourceIDs.remove(videoID)
        print("✅ Source cargado para: \(videoID)")
    }
    
    

    private func loadSourceForVideo(id: String, token: String) async {
        guard let index = videos.firstIndex(where: { $0.id == id }) else { return }
        if let src = await service.fetchVideoSources(videoID: id, token: token) {
            // Reemplaza el elemento completo para forzar que SwiftUI detecte el cambio
            var updated = videos[index]
            updated.videoURL = src
            videos[index] = updated
        }
    }

    // MARK: - Thumbnail (bajo demanda)
    func fetchThumbnail(for video: Video) async -> String? {
        guard let token = await getToken() else { return nil }
        return await service.fetchVideoThumbnail(videoID: video.id, token: token)
    }

    // MARK: - Update
    func updateVideo(video: Video, name: String, description: String?, longDescription: String?) async {
        guard let token = await getToken() else {
            errorMessage = "No se pudo obtener el token"
            return
        }
        do {
            try await service.updateVideo(
                videoID: video.id,
                token: token,
                name: name,
                description: description,
                longDescription: longDescription
            )
            // Actualiza localmente sin recargar todo
            if let index = videos.firstIndex(where: { $0.id == video.id }) {
                videos[index].name            = name
                videos[index].description     = description
                videos[index].longDescription = longDescription
            }
        } catch {
            errorMessage = "Error al actualizar: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete (versión async)
    func deleteVideo(video: Video) async {
        guard let token = await getToken() else {
            errorMessage = "No se pudo obtener el token"
            return
        }
        do {
            try await service.deleteVideo(videoID: video.id, token: token)
            videos.removeAll { $0.id == video.id }
        } catch {
            errorMessage = "Error al eliminar: \(error.localizedDescription)"
        }
    }
    
    func searchVideos(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        guard let token = await getToken() else {
            isSearching = false
            return
        }
        do {
            let results = try await service.searchVideos(query: query, token: token)
            searchResults = results
        } catch {
            searchResults = []
        }
        isSearching = false
    }
}

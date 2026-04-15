//
//  EditInfoVideoView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 23/07/25.
//


import SwiftUI

struct EditInfoVideoView: View {
    let video: Video
    @ObservedObject var viewModel: VideoViewModel
    @Binding var navigationPath: NavigationPath

    @Environment(\.dismiss) var dismiss

    @State private var name:            String
    @State private var shortDesc:       String
    @State private var longDesc:        String
    @State private var isSaving         = false
    @State private var showDeleteAlert  = false
    @State private var showToast        = false
    @State private var toastMessage     = ""
    @State private var isDeleting       = false

    init(video: Video, viewModel: VideoViewModel, navigationPath: Binding<NavigationPath>) {
        self.video      = video
        self.viewModel  = viewModel
        self._navigationPath = navigationPath
        self._name      = State(initialValue: video.name)
        self._shortDesc = State(initialValue: video.description ?? "")
        self._longDesc  = State(initialValue: video.longDescription ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {

                // MARK: - Header
                HStack(spacing: 16) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 20))
                            .foregroundStyle(.gray)
                    }
                    Text("Editar video")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()

                Divider()

                VStack(alignment: .leading, spacing: 28) {

                    // Nombre
                    fieldSection(title: "Nombre") {
                        TextField("Nombre del video", text: $name)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Descripción corta
                    fieldSection(title: "Descripción corta") {
                        TextEditor(text: $shortDesc)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Descripción larga
                    fieldSection(title: "Descripción larga") {
                        TextEditor(text: $longDesc)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Guardar
                    Button {
                        Task { await saveChanges() }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .frame(height: 48)
                                .foregroundStyle(.blue)
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Guardar cambios")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .disabled(isSaving || name.isEmpty)

                    Divider()

                    // Eliminar
                    Button {
                        showDeleteAlert = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .frame(height: 48)
                                .foregroundStyle(.red.opacity(0.1))
                            HStack {
                                Image(systemName: "trash")
                                Text("Eliminar video")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .disabled(isDeleting)
                }
                .padding()
            }
        }
        .alert("Eliminar video", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                Task { await deleteVideo() }
            }
        } message: {
            Text("¿Estás seguro? Esta acción no se puede deshacer.")
        }
        .overlay(
            Group {
                if showToast {
                    ToastView(toastMessage: $toastMessage, showToast: $showToast)
                }
            }
        )
    }

    // MARK: - Helper view
    @ViewBuilder
    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
    }

    // MARK: - Actions
    private func saveChanges() async {
        isSaving = true
        await viewModel.updateVideo(
            video: video,
            name: name,
            description: shortDesc.isEmpty ? nil : shortDesc,
            longDescription: longDesc.isEmpty ? nil : longDesc
        )
        isSaving = false
        toastMessage = "Video actualizado correctamente"
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showToast = false
            dismiss()
        }
    }

    private func deleteVideo() async {
        isDeleting = true
        await viewModel.deleteVideo(video: video)
        isDeleting = false
        // Regresa al feed
        navigationPath = NavigationPath()
    }
}

#Preview {
    EditInfoVideoView(
        video: Video(
            id: "123",
            accountId: "456",
            name: "Video de prueba",
            createdAt: "2025-01-01",
            state: "ACTIVE",
            createdBy: CreatedBy(type: "user", id: "1", email: "test@test.com"),
            description: "Descripción corta",
            longDescription: "Descripción larga de prueba",
            tags: []
        ),
        viewModel: VideoViewModel(),
        navigationPath: .constant(NavigationPath())
    )
}

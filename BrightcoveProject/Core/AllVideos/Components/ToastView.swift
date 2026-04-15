//
//  ToastView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 18/07/25.
//

import SwiftUI

struct ToastView: View {
    @Binding var toastMessage: String
    @Binding var showToast: Bool
    
    
    var body: some View {
        VStack {
            Text(toastMessage)
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 40)
            
            Spacer()
        }
        .animation(.easeInOut, value: showToast)
    }
}

#Preview {
    ToastPreviewWrapper()
}

// Vista auxiliar para la preview
struct ToastPreviewWrapper: View {
    @State private var toastMessage = "Vista previa del Toast"
    @State private var showToast = true
    
    var body: some View {
        ToastView(toastMessage: $toastMessage, showToast: $showToast)
    }
}


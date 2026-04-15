//
//  buttonView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 18/07/25.
//

import SwiftUI

struct buttonView: View {
    let name: String
    let color: Color
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action){
            Text(name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.white))
                .frame(width: 300, height: 50)
                .background(Color(color))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    buttonView(name: "Test Button", color: .black){
        print("Test ButtonView")
    }
}

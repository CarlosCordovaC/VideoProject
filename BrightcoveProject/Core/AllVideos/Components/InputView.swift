//
//  InputView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 15/07/25.
//

import SwiftUI

struct InputView: View {
    @Binding var text:String
    let title: String
    let placeholder: String
    var isSecureField = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12){
            VStack(){
                Text(title)
                    .foregroundStyle(Color(.darkGray))
                    .fontWeight(.semibold)
                    .font(.footnote)
            }
            
            VStack(){
                
                if isSecureField{
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 14))
                    
                }else{
                    TextField(placeholder, text: $text)
                        .font(.system(size: 14))
                }
                
                Divider()
                
            }
            .padding()
            .frame(width: 350, height: 70)
            .background(Color(.white))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        
        
    }
}

#Preview {
    InputView(text: .constant(""), title: "Test title", placeholder: "Test Placeholder", isSecureField: false)
}

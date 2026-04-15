//
//  TagsScrollView.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 20/07/25.
//

import SwiftUI

struct TagsScrollView: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal){
            HStack(){
                ForEach (tags, id: \.self) {tag in
                    Text(tag)
                }
                .frame(width: 100, height: 30)
                .overlay{
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(Color.blue.opacity(0.5))
                        
                    
                }
            }
            .padding()
        }
    }
}

#Preview {
    TagsScrollView(tags: ["TEST"])
}

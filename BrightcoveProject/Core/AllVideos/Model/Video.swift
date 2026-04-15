//
//  Coin.swift
//  BrightcoveProject
//
//  Created by Carlos Camberos Cordova on 23/06/25.
//
//  Coin.swift
//  BrightcoveProject

struct CreatedBy: Hashable {
    let type: String
    let id: String?
    let email: String?
}

struct Video: Identifiable, Hashable {
    let id: String
    let accountId: String
    var name: String                        // var — editable
    let createdAt: String
    let state: String
    let createdBy: CreatedBy
    var description: String?               // var — editable
    var longDescription: String?           // nuevo campo
    var thumbnailURL: String? = nil
    var videoURL: String? = nil
    var videoPreviewURL: String?
    var tags: [String]                     // var — editable

    static func == (lhs: Video, rhs: Video) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

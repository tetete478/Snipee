//
//  Snippet.swift
//  SnipeeIOS
//

import Foundation

enum SnippetType: String, Codable {
    case master
    case personal
}

struct Snippet: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var content: String
    var folder: String
    var type: SnippetType
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        folder: String,
        type: SnippetType,
        order: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.folder = folder
        self.type = type
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct SnippetFolder: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var snippets: [Snippet]
    var order: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        snippets: [Snippet] = [],
        order: Int
    ) {
        self.id = id
        self.name = name
        self.snippets = snippets
        self.order = order
    }
}

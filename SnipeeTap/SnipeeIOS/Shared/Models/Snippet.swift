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
    var description: String?
    var order: Int
    var createdAt: String?
    var updatedAt: String?

    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        folder: String,
        type: SnippetType,
        description: String? = nil,
        order: Int,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.folder = folder
        self.type = type
        self.description = description
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
    var updatedAt: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        snippets: [Snippet] = [],
        order: Int,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.snippets = snippets
        self.order = order
        self.updatedAt = updatedAt
    }
}

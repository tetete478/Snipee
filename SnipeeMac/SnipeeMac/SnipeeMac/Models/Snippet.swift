//
//  Untitled.swift
//  SnipeeMac
//
//  Created by てててMac on 2026/01/14.
//

//
//  Snippet.swift
//  SnipeeMac
//

import Foundation

enum SnippetType: String, Codable {
    case personal
    case master
}

struct Snippet: Codable, Identifiable {
    let id: String
    var title: String
    var content: String
    var folder: String
    var type: SnippetType
    var description: String?
    var order: Int
    
    init(id: String = UUID().uuidString, title: String, content: String, folder: String, type: SnippetType = .personal, description: String? = nil, order: Int = 0) {
        self.id = id
        self.title = title
        self.content = content
        self.folder = folder
        self.type = type
        self.description = description
        self.order = order
    }
}

struct SnippetFolder: Codable, Identifiable {
    let id: String
    var name: String
    var snippets: [Snippet]
    var order: Int
    
    init(id: String = UUID().uuidString, name: String, snippets: [Snippet] = [], order: Int = 0) {
        self.id = id
        self.name = name
        self.snippets = snippets
        self.order = order
    }
}

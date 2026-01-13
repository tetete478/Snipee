//
//  Department.swift
//  SnipeeMac
//

import Foundation

struct Department: Codable, Identifiable {
    let id: String
    var name: String
    var xmlFileId: String
    
    init(id: String = UUID().uuidString, name: String, xmlFileId: String) {
        self.id = id
        self.name = name
        self.xmlFileId = xmlFileId
    }
}

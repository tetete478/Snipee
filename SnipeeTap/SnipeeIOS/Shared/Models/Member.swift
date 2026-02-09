//
//  Member.swift
//  SnipeeIOS
//

import Foundation

struct Member: Identifiable, Codable, Equatable {
    var id: String
    var email: String
    var name: String
    var department: String
    var role: MemberRole
    var lastLoginAt: Date?

    init(
        id: String = UUID().uuidString,
        email: String,
        name: String,
        department: String,
        role: MemberRole = .member,
        lastLoginAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.department = department
        self.role = role
        self.lastLoginAt = lastLoginAt
    }
}

enum MemberRole: String, Codable {
    case admin
    case member
}

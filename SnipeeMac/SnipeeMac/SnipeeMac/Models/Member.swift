
//
//  Member.swift
//  SnipeeMac
//

import Foundation

enum MemberRole: String, Codable {
    case general = "一般"
    case admin = "管理者"
    case superAdmin = "最高管理者"
}

struct Member: Codable {
    var name: String
    var email: String
    var departments: [String]
    var role: MemberRole
    
    init(name: String, email: String, departments: [String], role: MemberRole = .general) {
        self.name = name
        self.email = email
        self.departments = departments
        self.role = role
    }
    
    var isAdmin: Bool {
        role == .admin || role == .superAdmin
    }
    
    var isSuperAdmin: Bool {
        role == .superAdmin
    }
}

//
//  SnipeeMacApp.swift
//  SnipeeMac
//

import SwiftUI

@main
struct SnipeeMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

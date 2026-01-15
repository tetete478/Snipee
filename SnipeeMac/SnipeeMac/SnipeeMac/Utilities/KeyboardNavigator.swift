//
//  KeyboardNavigator.swift
//  SnipeeMac
//

import AppKit

protocol KeyboardNavigatorDelegate: AnyObject {
    func navigateUp()
    func navigateDown()
    func navigateLeft()
    func navigateRight()
    func selectItem()
    func cancel()
    func selectNumber(_ number: Int)
}

class KeyboardNavigator {
    weak var delegate: KeyboardNavigatorDelegate?
    
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let delegate = delegate else { return false }
        
        // Number keys 1-9
        if let characters = event.charactersIgnoringModifiers,
           let number = Int(characters),
           number >= 1 && number <= 9 {
            delegate.selectNumber(number)
            return true
        }
        
        switch event.keyCode {
        case 126: // Up arrow
            delegate.navigateUp()
            return true
        case 125: // Down arrow
            delegate.navigateDown()
            return true
        case 123: // Left arrow
            delegate.navigateLeft()
            return true
        case 124: // Right arrow
            delegate.navigateRight()
            return true
        case 36: // Enter
            delegate.selectItem()
            return true
        case 53: // Escape
            delegate.cancel()
            return true
        default:
            return false
        }
    }
}

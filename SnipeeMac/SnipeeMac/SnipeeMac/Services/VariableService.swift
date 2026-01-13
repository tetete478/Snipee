
//
//  VariableService.swift
//  SnipeeMac
//

import Foundation

class VariableService {
    static let shared = VariableService()
    
    private init() {}
    
    func processVariables(_ text: String) -> String {
        var result = text
        let now = Date()
        let calendar = Calendar.current
        
        // {名前} - User name
        let settings = StorageService.shared.getSettings()
        result = result.replacingOccurrences(of: "{名前}", with: settings.userName)
        result = result.replacingOccurrences(of: "{name}", with: settings.userName)
        
        // {日付} - Today's date (YYYY/MM/DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        result = result.replacingOccurrences(of: "{日付}", with: dateFormatter.string(from: now))
        result = result.replacingOccurrences(of: "{date}", with: dateFormatter.string(from: now))
        
        // {年}, {月}, {日}
        result = result.replacingOccurrences(of: "{年}", with: String(calendar.component(.year, from: now)))
        result = result.replacingOccurrences(of: "{月}", with: String(calendar.component(.month, from: now)))
        result = result.replacingOccurrences(of: "{日}", with: String(calendar.component(.day, from: now)))
        
        // {時刻} - Current time (HH:mm)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        result = result.replacingOccurrences(of: "{時刻}", with: timeFormatter.string(from: now))
        result = result.replacingOccurrences(of: "{time}", with: timeFormatter.string(from: now))
        
        // {曜日} - Day of week
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        let weekdayIndex = calendar.component(.weekday, from: now) - 1
        result = result.replacingOccurrences(of: "{曜日}", with: weekdays[weekdayIndex])
        
        // {明日}, {明後日}
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            result = result.replacingOccurrences(of: "{明日}", with: dateFormatter.string(from: tomorrow))
        }
        if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: now) {
            result = result.replacingOccurrences(of: "{明後日}", with: dateFormatter.string(from: dayAfterTomorrow))
        }
        
        return result
    }
}

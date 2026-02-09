//
//  VariableService.swift
//  SnipeeIOS
//

import Foundation
import UIKit

class VariableService {
    static let shared = VariableService()
    
    private init() {}
    
    // MARK: - Date Formatting Helpers
    
    /// MM/DD形式でフォーマット
    private func formatMMDD(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    /// M月D日形式でフォーマット
    private func formatMonthDay(_ date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(month)月\(day)日"
    }
    
    /// 曜日を取得（短縮形）
    private func getWeekdayShort(_ date: Date) -> String {
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        return "（\(weekdays[weekdayIndex])）"
    }
    
    /// M月D日（曜日）形式でフォーマット
    private func formatWithWeekday(_ date: Date) -> String {
        return formatMonthDay(date) + getWeekdayShort(date)
    }
    
    /// タイムスタンプ形式でフォーマット
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    /// N日後の日付を取得（1日を除外）
    private func addDaysExcluding1st(_ date: Date, days: Int, alternativeDays: Int) -> Date {
        let calendar = Calendar.current
        guard let result = calendar.date(byAdding: .day, value: days, to: date) else {
            return date
        }
        
        // 1日だったら代替日数を使用
        if calendar.component(.day, from: result) == 1 {
            return calendar.date(byAdding: .day, value: alternativeDays, to: date) ?? date
        }
        
        return result
    }
    
    /// 連動する2つの日程を計算（重複なし、1日スキップ）
    private func calculateLinkedSchedule(baseDays: Int, alternativeDays: Int, from date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        
        // 日程1: baseDays日後（1日なら alternativeDays日後）
        let schedule1 = addDaysExcluding1st(date, days: baseDays, alternativeDays: alternativeDays)
        
        // 日程2: 日程1の翌日（ただし1日ならスキップ）
        guard let schedule2Base = calendar.date(byAdding: .day, value: 1, to: schedule1) else {
            return (schedule1, schedule1)
        }
        
        let schedule2: Date
        if calendar.component(.day, from: schedule2Base) == 1 {
            schedule2 = calendar.date(byAdding: .day, value: 1, to: schedule2Base) ?? schedule2Base
        } else {
            schedule2 = schedule2Base
        }
        
        return (schedule1, schedule2)
    }
    
    // MARK: - Main Processing
    
    func process(_ text: String) -> String {
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
        result = result.replacingOccurrences(of: "{{today}}", with: dateFormatter.string(from: now))
        
        // {年}, {月}, {日}
        result = result.replacingOccurrences(of: "{年}", with: String(calendar.component(.year, from: now)))
        result = result.replacingOccurrences(of: "{月}", with: String(calendar.component(.month, from: now)))
        result = result.replacingOccurrences(of: "{日}", with: String(calendar.component(.day, from: now)))
        result = result.replacingOccurrences(of: "{{year}}", with: String(calendar.component(.year, from: now)))
        result = result.replacingOccurrences(of: "{{month}}", with: String(calendar.component(.month, from: now)))
        result = result.replacingOccurrences(of: "{{day}}", with: String(calendar.component(.day, from: now)))
        
        // {時刻} - Current time (HH:mm)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        result = result.replacingOccurrences(of: "{時刻}", with: timeFormatter.string(from: now))
        result = result.replacingOccurrences(of: "{time}", with: timeFormatter.string(from: now))
        result = result.replacingOccurrences(of: "{{time}}", with: timeFormatter.string(from: now))
        
        // {曜日} - Day of week
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        let weekdayIndex = calendar.component(.weekday, from: now) - 1
        result = result.replacingOccurrences(of: "{曜日}", with: weekdays[weekdayIndex])
        result = result.replacingOccurrences(of: "{{weekday}}", with: weekdays[weekdayIndex])
        
        // {明日}, {明後日}
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            result = result.replacingOccurrences(of: "{明日}", with: dateFormatter.string(from: tomorrow))
            result = result.replacingOccurrences(of: "{{tomorrow}}", with: dateFormatter.string(from: tomorrow))
        }
        if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: now) {
            result = result.replacingOccurrences(of: "{明後日}", with: dateFormatter.string(from: dayAfterTomorrow))
        }
        
        // ========================================
        // 追加: Electron版互換の変数
        // ========================================
        
        // {今日:MM/DD}
        result = result.replacingOccurrences(of: "{今日:MM/DD}", with: formatMMDD(now))
        
        // {明日:MM/DD}
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            result = result.replacingOccurrences(of: "{明日:MM/DD}", with: formatMMDD(tomorrow))
        }
        
        // {タイムスタンプ}
        result = result.replacingOccurrences(of: "{タイムスタンプ}", with: formatTimestamp(now))
        
        // ========================================
        // 連動ペアA: 当日 & 1日後
        // ========================================
        let (scheduleA1, scheduleA2) = calculateLinkedSchedule(baseDays: 0, alternativeDays: 1, from: now)
        result = result.replacingOccurrences(
            of: "{当日:M月D日:曜日短（毎月1日は除外して翌日）}",
            with: formatWithWeekday(scheduleA1)
        )
        result = result.replacingOccurrences(
            of: "{1日後:M月D日:曜日短（毎月1日は除外して2日後）}",
            with: formatWithWeekday(scheduleA2)
        )
        
        // ========================================
        // 連動ペアB: 1日後 & 2日後
        // ========================================
        let (scheduleB1, scheduleB2) = calculateLinkedSchedule(baseDays: 1, alternativeDays: 2, from: now)
        result = result.replacingOccurrences(
            of: "{1日後:M月D日:曜日短（毎月1日は除外して2日後）}",
            with: formatWithWeekday(scheduleB1)
        )
        result = result.replacingOccurrences(
            of: "{2日後:M月D日:曜日短（毎月1日は除外して3日後）}",
            with: formatWithWeekday(scheduleB2)
        )
        
        // ========================================
        // 連動ペアC: 2日後 & 3日後
        // ========================================
        let (scheduleC1, scheduleC2) = calculateLinkedSchedule(baseDays: 2, alternativeDays: 3, from: now)
        result = result.replacingOccurrences(
            of: "{2日後:M月D日:曜日短（毎月1日は除外して3日後）}",
            with: formatWithWeekday(scheduleC1)
        )
        result = result.replacingOccurrences(
            of: "{3日後:M月D日:曜日短（毎月1日は除外して4日後）}",
            with: formatWithWeekday(scheduleC2)
        )
        
        // ========================================
        // iOS固有: クリップボード
        // ========================================
        if let clipboard = UIPasteboard.general.string {
            result = result.replacingOccurrences(of: "{{clipboard}}", with: clipboard)
        }
        
        return result
    }
}

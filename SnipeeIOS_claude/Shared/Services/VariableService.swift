//
//  VariableService.swift
//  SnipeeIOS
//

import Foundation

class VariableService {
    static let shared = VariableService()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    private init() {}

    func process(_ text: String) -> String {
        var result = text

        // Date variables
        result = processDateVariables(result)

        // Time variables
        result = processTimeVariables(result)

        // User variables
        result = processUserVariables(result)

        return result
    }

    private func processDateVariables(_ text: String) -> String {
        var result = text
        let now = Date()

        // {{today}} - 今日の日付
        dateFormatter.dateFormat = "yyyy/MM/dd"
        result = result.replacingOccurrences(of: "{{today}}", with: dateFormatter.string(from: now))

        // {{today_jp}} - 今日の日付（日本語）
        dateFormatter.dateFormat = "yyyy年M月d日"
        result = result.replacingOccurrences(of: "{{today_jp}}", with: dateFormatter.string(from: now))

        // {{year}} - 年
        dateFormatter.dateFormat = "yyyy"
        result = result.replacingOccurrences(of: "{{year}}", with: dateFormatter.string(from: now))

        // {{month}} - 月
        dateFormatter.dateFormat = "M"
        result = result.replacingOccurrences(of: "{{month}}", with: dateFormatter.string(from: now))

        // {{day}} - 日
        dateFormatter.dateFormat = "d"
        result = result.replacingOccurrences(of: "{{day}}", with: dateFormatter.string(from: now))

        // {{weekday}} - 曜日
        dateFormatter.dateFormat = "EEEE"
        result = result.replacingOccurrences(of: "{{weekday}}", with: dateFormatter.string(from: now))

        // {{weekday_short}} - 曜日（短縮）
        dateFormatter.dateFormat = "E"
        result = result.replacingOccurrences(of: "{{weekday_short}}", with: dateFormatter.string(from: now))

        // {{tomorrow}} - 明日
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) {
            dateFormatter.dateFormat = "yyyy/MM/dd"
            result = result.replacingOccurrences(of: "{{tomorrow}}", with: dateFormatter.string(from: tomorrow))
        }

        // {{next_week}} - 来週
        if let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: now) {
            dateFormatter.dateFormat = "yyyy/MM/dd"
            result = result.replacingOccurrences(of: "{{next_week}}", with: dateFormatter.string(from: nextWeek))
        }

        // {{next_month}} - 来月
        if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: now) {
            dateFormatter.dateFormat = "yyyy/MM/dd"
            result = result.replacingOccurrences(of: "{{next_month}}", with: dateFormatter.string(from: nextMonth))
        }

        return result
    }

    private func processTimeVariables(_ text: String) -> String {
        var result = text
        let now = Date()

        // {{time}} - 現在時刻
        dateFormatter.dateFormat = "HH:mm"
        result = result.replacingOccurrences(of: "{{time}}", with: dateFormatter.string(from: now))

        // {{time_full}} - 現在時刻（秒付き）
        dateFormatter.dateFormat = "HH:mm:ss"
        result = result.replacingOccurrences(of: "{{time_full}}", with: dateFormatter.string(from: now))

        // {{hour}} - 時
        dateFormatter.dateFormat = "H"
        result = result.replacingOccurrences(of: "{{hour}}", with: dateFormatter.string(from: now))

        // {{minute}} - 分
        dateFormatter.dateFormat = "m"
        result = result.replacingOccurrences(of: "{{minute}}", with: dateFormatter.string(from: now))

        return result
    }

    private func processUserVariables(_ text: String) -> String {
        var result = text

        // {{clipboard}} - クリップボード内容
        if let clipboard = UIPasteboard.general.string {
            result = result.replacingOccurrences(of: "{{clipboard}}", with: clipboard)
        }

        return result
    }
}

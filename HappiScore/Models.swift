import Foundation

struct HappinessInput {
    let mood: Double        // 1〜5
    let stress: Double      // 1〜5
    let satisfaction: Double // 1〜5

    let exercised: Bool
    let socialized: Bool
    let wentOutside: Bool
    let learned: Bool

    let sleepHours: Double
    let steps: Double
    let screenTimeHours: Double
}

struct HappinessCalculator {
    static func calculate(_ input: HappinessInput) -> Int {
        // 主観: 40点
        let moodScore =
            ((input.mood / 5.0) * 15) +
            (((6.0 - input.stress) / 5.0) * 10) +
            ((input.satisfaction / 5.0) * 15)

        // 行動: 30点
        var actionScore = 0.0
        if input.exercised { actionScore += 7.5 }
        if input.socialized { actionScore += 7.5 }
        if input.wentOutside { actionScore += 7.5 }
        if input.learned { actionScore += 7.5 }

        // 状態: 30点
        let sleepScore = min(input.sleepHours / 8.0, 1.0) * 10
        let stepScore = min(input.steps / 8000.0, 1.0) * 10
        let screenScore = max(0, 1.0 - input.screenTimeHours / 8.0) * 10

        let total = moodScore + actionScore + sleepScore + stepScore + screenScore
        return Int(min(max(total, 0), 100))
    }
}

struct DailyRecord: Codable, Identifiable {
    var id: String { date }
    let date: String // yyyy-MM-dd
    let score: Int
    let mood: Double
    let stress: Double
    let satisfaction: Double
    let exercised: Bool
    let socialized: Bool
    let wentOutside: Bool
    let learned: Bool
    let sleepHours: Double
    let steps: Double
    let screenTimeHours: Double

    static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    var displayDate: String {
        guard let d = Self.dateFormatter.date(from: date) else { return date }
        let df = DateFormatter()
        df.dateFormat = "M/d (E)"
        df.locale = Locale(identifier: "ja_JP")
        return df.string(from: d)
    }
}

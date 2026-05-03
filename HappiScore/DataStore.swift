import Foundation

final class DataStore {
    private static let key = "daily_records"

    static func save(_ record: DailyRecord) {
        var records = loadAll()
        records.removeAll { $0.date == record.date }
        records.append(record)
        records.sort { $0.date > $1.date }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func loadAll() -> [DailyRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([DailyRecord].self, from: data)
        else { return [] }
        return records
    }

    static func today() -> DailyRecord? {
        let today = DailyRecord.dateFormatter.string(from: Date())
        return loadAll().first { $0.date == today }
    }
}

import SwiftUI

struct HistoryView: View {
    @State private var records: [DailyRecord] = []

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("まだ記録がありません")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        // Weekly average
                        if records.count >= 2 {
                            let avg = records.prefix(7).reduce(0) { $0 + $1.score } / min(records.count, 7)
                            Section("直近7日の平均") {
                                HStack {
                                    Text("\(avg)点")
                                        .font(.title.bold())
                                        .foregroundStyle(scoreColor(avg))
                                    Spacer()
                                    Text("\(min(records.count, 7))日分")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Section("記録一覧") {
                            ForEach(records) { record in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.displayDate)
                                            .font(.subheadline)
                                        HStack(spacing: 8) {
                                            badge("主観", value: subjectiveScore(record))
                                            badge("行動", value: actionScore(record))
                                            badge("状態", value: stateScore(record))
                                        }
                                    }

                                    Spacer()

                                    Text("\(record.score)")
                                        .font(.title.bold())
                                        .foregroundStyle(scoreColor(record.score))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("履歴")
            .onAppear {
                records = DataStore.loadAll()
            }
        }
    }

    private func badge(_ label: String, value: Int) -> some View {
        Text("\(label) \(value)")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(6)
    }

    private func subjectiveScore(_ r: DailyRecord) -> Int {
        Int(((r.mood / 5.0) * 15) + (((6.0 - r.stress) / 5.0) * 10) + ((r.satisfaction / 5.0) * 15))
    }

    private func actionScore(_ r: DailyRecord) -> Int {
        var s = 0.0
        if r.exercised { s += 7.5 }
        if r.socialized { s += 7.5 }
        if r.wentOutside { s += 7.5 }
        if r.learned { s += 7.5 }
        return Int(s)
    }

    private func stateScore(_ r: DailyRecord) -> Int {
        let sleep = min(r.sleepHours / 8.0, 1.0) * 10
        let step = min(r.steps / 8000.0, 1.0) * 10
        let screen = max(0, 1.0 - r.screenTimeHours / 8.0) * 10
        return Int(sleep + step + screen)
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        case 40..<60: return .yellow
        default: return .red
        }
    }
}

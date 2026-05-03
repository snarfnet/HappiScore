import SwiftUI

struct HomeView: View {
    @State private var mood = 3.0
    @State private var stress = 3.0
    @State private var satisfaction = 3.0

    @State private var exercised = false
    @State private var socialized = false
    @State private var wentOutside = false
    @State private var learned = false

    @State private var sleepHours = 7.0
    @State private var steps = 5000.0
    @State private var screenTimeHours = 4.0

    @State private var saved = false
    @State private var healthKitManager = HealthKitManager()

    var score: Int {
        HappinessCalculator.calculate(
            HappinessInput(
                mood: mood,
                stress: stress,
                satisfaction: satisfaction,
                exercised: exercised,
                socialized: socialized,
                wentOutside: wentOutside,
                learned: learned,
                sleepHours: sleepHours,
                steps: steps,
                screenTimeHours: screenTimeHours
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Score display
                    VStack(spacing: 8) {
                        Text("今日の幸福度")
                            .font(.headline)

                        Text("\(score)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(scoreColor(score))

                        Text(scoreMessage(score))
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    // 主観スコア (40点)
                    sectionHeader("主観", points: "40点")
                    scoreSlider(title: "気分", value: $mood, labels: ["低", "高"])
                    scoreSlider(title: "ストレス", value: $stress, labels: ["低", "高"])
                    scoreSlider(title: "満足度", value: $satisfaction, labels: ["低", "高"])

                    // 行動スコア (30点)
                    sectionHeader("行動", points: "30点")
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("運動した", isOn: $exercised)
                        Toggle("人と話した", isOn: $socialized)
                        Toggle("外出した", isOn: $wentOutside)
                        Toggle("学んだ", isOn: $learned)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // 状態スコア (30点)
                    sectionHeader("状態", points: "30点")
                    stateSlider(title: "睡眠", value: $sleepHours, range: 0...12, unit: "時間", step: 0.5)
                    stateSlider(title: "歩数", value: $steps, range: 0...20000, unit: "歩", step: 500)
                    stateSlider(title: "スマホ時間", value: $screenTimeHours, range: 0...12, unit: "時間", step: 0.5)

                    // Save button
                    Button {
                        saveRecord()
                    } label: {
                        Text("今日の記録を保存")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Spacer(minLength: 60)
                }
                .padding()
            }
            .navigationTitle("HappiScore")
            .task {
                loadTodayIfExists()
                do {
                    try await healthKitManager.requestAuthorization()
                    steps = try await healthKitManager.fetchTodaySteps()
                    sleepHours = try await healthKitManager.fetchLastNightSleepHours()
                } catch {
                    print("HealthKit error:", error)
                }
            }
        }
        .overlay {
            if saved {
                VStack {
                    Spacer()
                    Text("保存しました")
                        .font(.headline)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Components

    private func sectionHeader(_ title: String, points: String) -> some View {
        HStack {
            Text(title)
                .font(.title3.bold())
            Spacer()
            Text(points)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.top, 8)
    }

    private func scoreSlider(title: String, value: Binding<Double>, labels: [String]) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.title3.bold())
            }

            Slider(value: value, in: 1...5, step: 1)
                .tint(.orange)

            HStack {
                Text(labels[0]).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(labels[1]).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func stateSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String, step: Double) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(step < 1 ? String(format: "%.1f %@", value.wrappedValue, unit) : "\(Int(value.wrappedValue)) \(unit)")
                    .font(.title3.bold())
            }

            Slider(value: value, in: range, step: step)
                .tint(.orange)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Logic

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        case 40..<60: return .yellow
        default: return .red
        }
    }

    private func scoreMessage(_ score: Int) -> String {
        switch score {
        case 80...100: return "かなり良い日です"
        case 60..<80: return "安定した日です"
        case 40..<60: return "少し整える余地があります"
        default: return "今日は休む優先でOK"
        }
    }

    private func saveRecord() {
        let record = DailyRecord(
            date: DailyRecord.dateFormatter.string(from: Date()),
            score: score,
            mood: mood,
            stress: stress,
            satisfaction: satisfaction,
            exercised: exercised,
            socialized: socialized,
            wentOutside: wentOutside,
            learned: learned,
            sleepHours: sleepHours,
            steps: steps,
            screenTimeHours: screenTimeHours
        )
        DataStore.save(record)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }

    private func loadTodayIfExists() {
        guard let r = DataStore.today() else { return }
        mood = r.mood
        stress = r.stress
        satisfaction = r.satisfaction
        exercised = r.exercised
        socialized = r.socialized
        wentOutside = r.wentOutside
        learned = r.learned
        sleepHours = r.sleepHours
        steps = r.steps
        screenTimeHours = r.screenTimeHours
    }
}

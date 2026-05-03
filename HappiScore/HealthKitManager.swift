import HealthKit

final class HealthKitManager {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard
            let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        else {
            throw HealthKitError.typeNotAvailable
        }

        let readTypes: Set<HKObjectType> = [
            stepType,
            sleepType
        ]

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchTodaySteps() async throws -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date()
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = result?
                    .sumQuantity()?
                    .doubleValue(for: .count()) ?? 0

                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }

    func fetchLastNightSleepHours() async throws -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAvailable
        }

        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .hour, value: -24, to: end)!

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let sleepSamples = samples as? [HKCategorySample] ?? []

                let asleepSeconds = sleepSamples
                    .filter { sample in
                        sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                continuation.resume(returning: asleepSeconds / 3600)
            }

            healthStore.execute(query)
        }
    }
}

enum HealthKitError: Error {
    case notAvailable
    case typeNotAvailable
}

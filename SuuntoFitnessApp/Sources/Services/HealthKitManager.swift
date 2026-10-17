import Foundation
import HealthKit
import Combine

/// Apple HealthKit 데이터 동기화 및 쿼리 매니저
@MainActor
public final class HealthKitManager: ObservableObject {
    public static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    // 발행 프로퍼티
    @Published public var isAuthorized: Bool = false
    @Published public var totalStepsToday: Int = 0
    @Published public var workoutStepsToday: Int = 0
    @Published public var activeCaloriesToday: Int = 0
    @Published public var currentHeartRate: Int? = nil
    @Published public var latestHrvSDNN: Double? = nil
    @Published public var lastNightSleepSeconds: TimeInterval = 0
    @Published public var past42DaysWorkouts: [HKWorkout] = []
    
    private init() {}
    
    // MARK: - 1. HealthKit 권한 요청
    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        // 읽기 권한 타입 정의
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let workoutType = HKObjectType.workoutType()
        
        let readTypes: Set<HKObjectType> = [
            stepType, calorieType, heartRateType, hrvType, sleepType, workoutType
        ]
        
        // 쓰기 권한 타입 (자체 러닝 기록 저장용)
        let shareTypes: Set<HKSampleType> = [workoutType, stepType, calorieType]
        
        try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
        self.isAuthorized = true
        
        // 권한 획득 즉시 데이터 갱신
        await refreshAllData()
    }
    
    // MARK: - 2. 모든 건강 데이터 통합 갱신
    public func refreshAllData() async {
        guard isAuthorized else { return }
        
        async let steps = fetchTotalStepsToday()
        async let workoutSteps = fetchWorkoutStepsToday()
        async let calories = fetchCaloriesToday()
        async let hr = fetchLatestHeartRate()
        async let hrv = fetchLatestHRV()
        async let sleep = fetchLastNightSleepDuration()
        async let pastWorkouts = fetchPast42DaysWorkouts()
        
        self.totalStepsToday = (try? await steps) ?? 0
        self.workoutStepsToday = (try? await workoutSteps) ?? 0
        self.activeCaloriesToday = (try? await calories) ?? 0
        self.currentHeartRate = try? await hr
        self.latestHrvSDNN = try? await hrv
        self.lastNightSleepSeconds = (try? await sleep) ?? 0
        self.past42DaysWorkouts = (try? await pastWorkouts) ?? []
    }
    
    // MARK: - 3. 오늘 총 걸음 수 (HealthKit 기본 전체 걸음)
    public func fetchTotalStepsToday() async throws -> Int {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 4. 오늘 '운동 세션' 동안 기록된 걸음 수
    public func fetchWorkoutStepsToday() async throws -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        // 오늘의 운동 세션 목록 가져오기
        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let workoutList = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workoutList)
            }
            healthStore.execute(query)
        }
        
        // 각 운동 세션의 시간 구간에 발생한 걸음 수 합산
        var totalWorkoutSteps = 0
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        for workout in workouts {
            let intervalPredicate = HKQuery.predicateForSamples(
                withStart: workout.startDate,
                end: workout.endDate,
                options: [.strictStartDate, .strictEndDate]
            )
            
            let stepsInWorkout = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: intervalPredicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let count = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    continuation.resume(returning: Int(count))
                }
                self.healthStore.execute(query)
            }
            totalWorkoutSteps += stepsInWorkout
        }
        
        return totalWorkoutSteps
    }
    
    // MARK: - 5. 오늘 활동 소모 칼로리
    public func fetchCaloriesToday() async throws -> Int {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: calorieType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let kcal = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: Int(kcal))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 6. 최근 심박수 & HRV
    public func fetchLatestHeartRate() async throws -> Int? {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        return try await fetchMostRecentQuantity(for: hrType, unit: HKUnit.count().unitDivided(by: HKUnit.minute()))
            .map { Int($0) }
    }
    
    public func fetchLatestHRV() async throws -> Double? {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        return try await fetchMostRecentQuantity(for: hrvType, unit: HKUnit.secondUnit(with: .milli))
    }
    
    // MARK: - 7. 어제 밤 수면 시간
    public func fetchLastNightSleepDuration() async throws -> TimeInterval {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let yesterdayNoon = calendar.date(byAdding: .hour, value: -24, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: yesterdayNoon, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                // 실제 수면(asleepCore, asleepDeep, asleepREM 등) 시간만 합산
                let totalSleep = sleepSamples.filter {
                    $0.value != HKCategoryValueSleepAnalysis.awake.rawValue
                }.reduce(0.0) { sum, sample in
                    sum + sample.endDate.timeIntervalSince(sample.startDate)
                }
                continuation.resume(returning: totalSleep)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 8. 순토 CTL/ATL 연산용 최근 42일 운동 데이터
    public func fetchPast42DaysWorkouts() async throws -> [HKWorkout] {
        let calendar = Calendar.current
        guard let fortyTwoDaysAgo = calendar.date(byAdding: .day, value: -42, to: Date()) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: fortyTwoDaysAgo, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            healthStore.execute(query)
        }
    }
    
    // 공통 최근 수치 쿼리 헬퍼
    private func fetchMostRecentQuantity(for quantityType: HKQuantityType, unit: HKUnit) async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }
}

public enum HealthKitError: Error, LocalizedError {
    case notAvailableOnDevice
    
    public var errorDescription: String? {
        switch self {
        case .notAvailableOnDevice:
            return "이 기기에서는 Apple HealthKit을 사용할 수 없습니다."
        }
    }
}

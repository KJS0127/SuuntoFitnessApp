import Foundation
import CoreLocation

// MARK: - 걸음 수 3단계 세분화 모델
public struct StepCountBreakdown: Codable, Hashable, Sendable {
    /// 1. HealthKit에서 수집된 일일 총 걸음 수
    public var totalSteps: Int
    /// 2. 60 spm 이상 15초 이상 지속 보행으로 필터링된 '진짜 걸음 수'
    public var realSteps: Int
    /// 3. 러닝/워킹 공식 운동 세션 기록 중 발생한 걸음 수
    public var workoutSteps: Int
    
    public init(totalSteps: Int = 0, realSteps: Int = 0, workoutSteps: Int = 0) {
        self.totalSteps = totalSteps
        self.realSteps = realSteps
        self.workoutSteps = workoutSteps
    }
}

// MARK: - 순토 훈련 부하 모델 (Training Load)
public struct TrainingLoadMetrics: Codable, Hashable, Sendable {
    /// CTL (Chronic Training Load / 체력): 지난 42일 가중 평균
    public var ctl: Double
    /// ATL (Acute Training Load / 피로도): 지난 7일 가중 평균
    public var atl: Double
    /// TSB (Training Stress Balance / 컨디션): CTL - ATL
    public var tsb: Double {
        return ctl - atl
    }
    /// 최근 운동의 TSS (Training Stress Score)
    public var recentTSS: Double
    
    public init(ctl: Double = 0, atl: Double = 0, recentTSS: Double = 0) {
        self.ctl = ctl
        self.atl = atl
        self.recentTSS = recentTSS
    }
}

// MARK: - 신체 리소스 및 웰니스 모델 (Resources & Health)
public struct BodyWellnessMetrics: Codable, Hashable, Sendable {
    /// 리소스 (바디 배터리 잔여량: 0 ~ 100%)
    public var resourcePercentage: Int
    /// 오늘 심박수 (현재 또는 안정시 심박수)
    public var currentHeartRate: Int?
    /// HRV (심박 변이도 - ms)
    public var hrvSDNN: Double?
    /// 어제 밤 수면 시간 (초 단위)
    public var sleepDurationSeconds: TimeInterval
    /// 목표 수면 대비 차이 (시간 단위, 예: -1.5시간)
    public var sleepDebtHours: Double
    
    public init(
        resourcePercentage: Int = 0,
        currentHeartRate: Int? = nil,
        hrvSDNN: Double? = nil,
        sleepDurationSeconds: TimeInterval = 0,
        sleepDebtHours: Double = 0
    ) {
        self.resourcePercentage = resourcePercentage
        self.currentHeartRate = currentHeartRate
        self.hrvSDNN = hrvSDNN
        self.sleepDurationSeconds = sleepDurationSeconds
        self.sleepDebtHours = sleepDebtHours
    }
}

// MARK: - 커뮤트(출퇴근) 환경 모델
public struct CommuteMetrics: Codable, Hashable, Sendable {
    /// 이번 달 절감한 이산화탄소 (kg CO2e)
    public var co2SavedKg: Double
    /// 커뮤트 운동 횟수 (자전거, 걷기, 달리기)
    public var bikeCount: Int
    public var runCount: Int
    public var walkCount: Int
    
    public init(co2SavedKg: Double = 0, bikeCount: Int = 0, runCount: Int = 0, walkCount: Int = 0) {
        self.co2SavedKg = co2SavedKg
        self.bikeCount = bikeCount
        self.runCount = runCount
        self.walkCount = walkCount
    }
}

// MARK: - 일일 운동 및 주간 요약 모델
public struct DailyActivitySummary: Identifiable, Codable, Hashable, Sendable {
    public var id: Date { date }
    public var date: Date
    public var steps: StepCountBreakdown
    public var caloriesBurnedKcal: Int
    public var activeDurationSeconds: TimeInterval
    public var elevationGainMeters: Double
    /// 운동 완료 여부 (최근 30일 잔디 매트릭스용)
    public var hasCompletedWorkout: Bool
    
    public init(
        date: Date = Date(),
        steps: StepCountBreakdown = StepCountBreakdown(),
        caloriesBurnedKcal: Int = 0,
        activeDurationSeconds: TimeInterval = 0,
        elevationGainMeters: Double = 0,
        hasCompletedWorkout: Bool = false
    ) {
        self.date = date
        self.steps = steps
        self.caloriesBurnedKcal = caloriesBurnedKcal
        self.activeDurationSeconds = activeDurationSeconds
        self.elevationGainMeters = elevationGainMeters
        self.hasCompletedWorkout = hasCompletedWorkout
    }
}

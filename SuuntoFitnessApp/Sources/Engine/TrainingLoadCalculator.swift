import Foundation
import HealthKit

/// 순토(Suunto) 트레이닝 피크 기준 훈련 부하(CTL, ATL, TSB, TSS) 정밀 계산 엔진
public final class TrainingLoadCalculator {
    public static let shared = TrainingLoadCalculator()
    
    private init() {}
    
    // MARK: - 1. 단일 운동 세션 TSS (Training Stress Score) 계산
    /// - Parameters:
    ///   - durationSeconds: 운동 시간 (초)
    ///   - avgHeartRate: 평균 심박수
    ///   - maxHeartRate: 최대 심박수 (기본값: 190 또는 220 - 나이)
    ///   - restingHeartRate: 안정시 심박수 (기본값: 60)
    public func calculateTSS(
        durationSeconds: TimeInterval,
        avgHeartRate: Int,
        maxHeartRate: Int = 188,
        restingHeartRate: Int = 60
    ) -> Double {
        guard durationSeconds > 0 && maxHeartRate > restingHeartRate else { return 0 }
        
        // 심박 예비력 기반 강도 지수 (HR Reserve Intensity Factor)
        let hrReserve = Double(maxHeartRate - restingHeartRate)
        let activeReserve = Double(max(0, avgHeartRate - restingHeartRate))
        let intensityFactor = min(1.2, max(0.4, activeReserve / hrReserve))
        
        // 표준 TSS 수식: (시간(초) x IF^2 x 100) / 3600
        let hours = durationSeconds / 3600.0
        let tss = hours * pow(intensityFactor, 2) * 100.0
        return max(1.0, tss)
    }
    
    // MARK: - 2. 과거 42일치 운동 데이터를 바탕으로 한 CTL / ATL / TSB 지수 이동 평균(EMA) 산출
    /// - Parameter workouts: HealthKit에서 가져온 최근 42일간의 워크아웃 리스트
    /// - Returns: 계산된 TrainingLoadMetrics (CTL, ATL, TSB)
    public func calculateTrainingLoad(from workouts: [HKWorkout]) -> TrainingLoadMetrics {
        guard !workouts.isEmpty else {
            // 과거 기록이 없는 경우 기본 기준치
            return TrainingLoadMetrics(ctl: 0, atl: 0, recentTSS: 0)
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 42일간의 일별 TSS 합산 맵 생성 (Day 0 ~ Day 41)
        var dailyTSSMap: [Int: Double] = [:]
        for i in 0..<42 {
            dailyTSSMap[i] = 0.0
        }
        
        for workout in workouts {
            let daysAgo = calendar.dateComponents([.day], from: workout.startDate, to: today).day ?? 0
            if daysAgo >= 0 && daysAgo < 42 {
                // 심박 데이터가 없는 일반 운동의 경우 칼로리와 지속 시간으로 TSS 근사치 계산
                let duration = workout.duration
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                let approximateTSS = max(10.0, (duration / 3600.0) * 55.0 + (calories / 20.0))
                dailyTSSMap[daysAgo, default: 0.0] += approximateTSS
            }
        }
        
        // 지수 이동 가중치(EMA) 시뮬레이션 (41일 전 -> 오늘)
        var currentCTL: Double = 0.0
        var currentATL: Double = 0.0
        
        // 42일 시상수
        let ctlLambda = 1.0 - exp(-1.0 / 42.0)
        let atlLambda = 1.0 - exp(-1.0 / 7.0)
        
        for dayIndex in (0..<42).reversed() {
            let dayTSS = dailyTSSMap[dayIndex] ?? 0.0
            currentCTL = currentCTL + (dayTSS - currentCTL) * ctlLambda
            currentATL = currentATL + (dayTSS - currentATL) * atlLambda
        }
        
        let recentTSS = dailyTSSMap[0] ?? (dailyTSSMap[1] ?? 50.0)
        
        return TrainingLoadMetrics(
            ctl: currentCTL,
            atl: currentATL,
            recentTSS: recentTSS
        )
    }
}

import Foundation
import CoreLocation

public enum MockFitnessData {
    /// 오늘 실시간 지표 샘플
    public static let sampleSteps = StepCountBreakdown(
        totalSteps: 11450,
        realSteps: 9820,
        workoutSteps: 6180
    )
    
    public static let sampleDailyGoal = DailyGoal(
        targetRealSteps: 10000,
        targetCaloriesKcal: 500,
        targetActiveTimeSeconds: 1800,
        targetWeeklyDistanceMeters: 15000,
        isNotificationEnabled: true
    )
    
    public static let sampleTrainingLoad = TrainingLoadMetrics(
        ctl: 48.5,
        atl: 54.2,
        recentTSS: 58.0
    )
    
    public static let sampleWellness = BodyWellnessMetrics(
        resourcePercentage: 76,
        currentHeartRate: 68,
        hrvSDNN: 52.4,
        sleepDurationSeconds: 26400, // 7시간 20분
        sleepDebtHours: -0.66
    )
    
    public static let sampleCommute = CommuteMetrics(
        co2SavedKg: 14.8,
        bikeCount: 6,
        runCount: 2,
        walkCount: 15
    )
    
    /// 최근 30일 일별 활동 히스토리 (잔디 캘린더 및 차트용)
    public static var sampleMonthlyHistory: [DailyActivitySummary] {
        var list: [DailyActivitySummary] = []
        let calendar = Calendar.current
        let today = Date()
        
        for dayOffset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let hasWorkout = (dayOffset % 2 == 0) || (dayOffset % 5 == 0)
            let total = hasWorkout ? Int.random(in: 9000...13000) : Int.random(in: 3000...7500)
            let real = Int(Double(total) * Double.random(in: 0.82...0.91))
            let workout = hasWorkout ? Int.random(in: 4500...7000) : 0
            
            let item = DailyActivitySummary(
                date: date,
                steps: StepCountBreakdown(totalSteps: total, realSteps: real, workoutSteps: workout),
                caloriesBurnedKcal: hasWorkout ? Int.random(in: 550...890) : Int.random(in: 200...400),
                activeDurationSeconds: hasWorkout ? TimeInterval.random(in: 2100...3800) : TimeInterval.random(in: 600...1500),
                elevationGainMeters: hasWorkout ? Double.random(in: 30...85) : 10.0,
                hasCompletedWorkout: hasWorkout
            )
            list.append(item)
        }
        return list
    }
    
    /// 스크린샷 1번을 그대로 복원한 단일 러닝 세션 샘플 (울산대공원 코스)
    public static let sampleRunningWorkout: WorkoutRecord = {
        // 울산대공원 주변 GPS 모의 트랙 생성
        let centerLat = 35.5348
        let centerLon = 129.3087
        var points: [TrackPoint] = []
        let startTime = Date().addingTimeInterval(-1962.1)
        
        for i in 0..<40 {
            let offset = Double(i) * 0.0006
            let pt = TrackPoint(
                latitude: centerLat + (sin(offset * 5) * 0.003) - (Double(i) * 0.0002),
                longitude: centerLon + (cos(offset * 3) * 0.004) + offset,
                altitude: 45.0 + sin(Double(i)) * 12.0,
                timestamp: startTime.addingTimeInterval(Double(i) * 49),
                speedMps: Double.random(in: 2.3...2.8)
            )
            points.append(pt)
        }
        
        return WorkoutRecord(
            id: UUID(),
            activityType: .running,
            startDate: startTime,
            endDate: Date(),
            deviceName: "Suunto Spartan Sport WHR",
            durationSeconds: 1962.1, // 32'42.10
            distanceMeters: 5010.0,  // 5.01 km
            averageHeartRateBpm: 162,
            maxHeartRateBpm: 178,
            averagePaceSecondsPerKm: 392.0, // 06'32 /km
            ngpSecondsPerKm: 380.0,         // 06'20 /km (NGP®)
            elevationGainMeters: 51.0,      // 상승 51m
            tss: 58.0,                      // TSS 58
            cadenceSpm: 167,                // 평균 167 spm
            caloriesBurnedKcal: 836,        // 836 kcal
            feeling: .good,
            weather: WorkoutWeather(
                temperatureCelsius: 11.0,
                windSpeedMps: 3.0,
                symbolName: "sun.max.fill",
                locationName: "울산광역시"
            ),
            achievements: ["이 경로에서 두 번째로 빠른 시간", "2달 내 첫 번째 달리기"],
            trackPoints: points
        )
    }()
}

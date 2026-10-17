import Foundation

// MARK: - 일일 운동 목표 모델
public struct DailyGoal: Codable, Hashable, Sendable {
    /// 일일 진짜 걸음 수 목표 (기본: 10,000보)
    public var targetRealSteps: Int
    /// 일일 활동 칼로리 목표 (기본: 500 kcal)
    public var targetCaloriesKcal: Int
    /// 일일 운동 시간 목표 (기본: 30분 = 1800초)
    public var targetActiveTimeSeconds: TimeInterval
    /// 주간 러닝 거리 목표 (기본: 15km = 15,000m)
    public var targetWeeklyDistanceMeters: Double
    /// 목표 달성 푸시 알림 허용 여부
    public var isNotificationEnabled: Bool
    
    public init(
        targetRealSteps: Int = 10000,
        targetCaloriesKcal: Int = 500,
        targetActiveTimeSeconds: TimeInterval = 1800,
        targetWeeklyDistanceMeters: Double = 15000,
        isNotificationEnabled: Bool = true
    ) {
        self.targetRealSteps = targetRealSteps
        self.targetCaloriesKcal = targetCaloriesKcal
        self.targetActiveTimeSeconds = targetActiveTimeSeconds
        self.targetWeeklyDistanceMeters = targetWeeklyDistanceMeters
        self.isNotificationEnabled = isNotificationEnabled
    }
}

// MARK: - 업적 배지 모델 (게이미피케이션)
public struct AchievementBadge: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var description: String
    public var iconName: String
    public var isUnlocked: Bool
    public var unlockedDate: Date?
    
    public init(
        id: String,
        title: String,
        description: String,
        iconName: String,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
    
    /// 기본 배지 셋
    public static let standardBadges: [AchievementBadge] = [
        AchievementBadge(id: "first_run", title: "첫 번째 러닝", description: "앱을 통해 첫 러닝 세션을 기록했습니다.", iconName: "figure.run.circle.fill", isUnlocked: true, unlockedDate: Date().addingTimeInterval(-86400 * 5)),
        AchievementBadge(id: "real_10k_steps", title: "진짜 10,000보 클럽", description: "유효 활동 걸음으로만 하루 10,000보를 달성했습니다.", iconName: "flame.circle.fill", isUnlocked: true, unlockedDate: Date().addingTimeInterval(-86400 * 2)),
        AchievementBadge(id: "streak_3days", title: "3일 연속 달성", description: "3일 연속 일일 목표를 100% 달성했습니다.", iconName: "bolt.badge.clock.fill", isUnlocked: false),
        AchievementBadge(id: "streak_7days", title: "주간 마스터", description: "7일 연속 일일 목표를 100% 달성했습니다.", iconName: "crown.fill", isUnlocked: false),
        AchievementBadge(id: "distance_5k", title: "5km 완주", description: "한 번의 러닝으로 5km 이상 달렸습니다.", iconName: "medal.fill", isUnlocked: true, unlockedDate: Date().addingTimeInterval(-86400)),
        AchievementBadge(id: "night_runner", title: "나이트 러너", description: "오후 8시 이후 3km 이상 달렸습니다.", iconName: "moon.stars.fill", isUnlocked: true, unlockedDate: Date().addingTimeInterval(-86400 * 3)),
        AchievementBadge(id: "elevation_conqueror", title: "고도 정복자", description: "누적 상승 고도 100m를 돌파했습니다.", iconName: "mountain.2.fill", isUnlocked: false)
    ]
}

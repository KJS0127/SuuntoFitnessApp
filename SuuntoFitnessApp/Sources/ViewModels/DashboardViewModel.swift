import SwiftUI
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    // MARK: - 네비게이션 & 탭 상태
    public enum ActiveTab: String, CaseIterable {
        case dashboard = "대시보드"
        case activities = "활동"
    }
    
    @Published public var selectedTab: ActiveTab = .dashboard
    @Published public var isWatchConnected: Bool = true
    @Published public var showWorkoutDetail: Bool = false
    @Published public var showGoalSettingSheet: Bool = false
    @Published public var showBadgeCollectionSheet: Bool = false
    @Published public var showGoalCelebrationModal: Bool = false
    @Published public var celebratedBadge: AchievementBadge? = nil
    
    // MARK: - 데이터 프로퍼티
    @Published public var stepBreakdown: StepCountBreakdown
    @Published public var dailyGoal: DailyGoal
    @Published public var trainingLoad: TrainingLoadMetrics
    @Published public var wellness: BodyWellnessMetrics
    @Published public var commute: CommuteMetrics
    @Published public var monthlyHistory: [DailyActivitySummary]
    @Published public var recentWorkout: WorkoutRecord?
    @Published public var badges: [AchievementBadge]
    
    private var hasCelebratedToday: Bool = false
    
    // MARK: - 센서 및 계산 엔진 연동
    private let stepCoordinator = StepTrackingCoordinator.shared
    private let healthKitManager = HealthKitManager.shared
    private let trainingLoadCalculator = TrainingLoadCalculator.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        stepBreakdown: StepCountBreakdown = MockFitnessData.sampleSteps,
        dailyGoal: DailyGoal = MockFitnessData.sampleDailyGoal,
        trainingLoad: TrainingLoadMetrics = MockFitnessData.sampleTrainingLoad,
        wellness: BodyWellnessMetrics = MockFitnessData.sampleWellness,
        commute: CommuteMetrics = MockFitnessData.sampleCommute,
        monthlyHistory: [DailyActivitySummary] = MockFitnessData.sampleMonthlyHistory,
        recentWorkout: WorkoutRecord? = MockFitnessData.sampleRunningWorkout,
        badges: [AchievementBadge] = AchievementBadge.standardBadges
    ) {
        self.stepBreakdown = stepBreakdown
        self.dailyGoal = dailyGoal
        self.trainingLoad = trainingLoad
        self.wellness = wellness
        self.commute = commute
        self.monthlyHistory = monthlyHistory
        self.recentWorkout = recentWorkout
        self.badges = badges
        
        bindLiveServices()
    }
    
    // MARK: - 실시간 센서 및 엔진 바인딩
    private func bindLiveServices() {
        // 1. 실시간 3단 걸음 수 구독
        stepCoordinator.$currentBreakdown
            .sink { [weak self] liveBreakdown in
                guard let self = self else { return }
                if liveBreakdown.totalSteps > 0 || liveBreakdown.realSteps > 0 {
                    self.stepBreakdown = liveBreakdown
                    self.checkGoalAchievement()
                }
            }
            .store(in: &cancellables)
        
        // 2. HealthKit 웰니스(심박, HRV, 수면, 칼로리) 실시간 동기화
        Publishers.CombineLatest4(
            healthKitManager.$currentHeartRate,
            healthKitManager.$latestHrvSDNN,
            healthKitManager.$lastNightSleepSeconds,
            healthKitManager.$activeCaloriesToday
        )
        .sink { [weak self] hr, hrv, sleepSec, calories in
            guard let self = self else { return }
            if let hr = hr { self.wellness.currentHeartRate = hr }
            if let hrv = hrv {
                self.wellness.hrvSDNN = hrv
                // HRV 기반 리소스(바디배터리) 동적 산출: HRV가 높을수록 회복도 상승
                let dynamicResource = min(98, max(45, Int((hrv / 65.0) * 80.0)))
                self.wellness.resourcePercentage = dynamicResource
            }
            if sleepSec > 0 { self.wellness.sleepDurationSeconds = sleepSec }
        }
        .store(in: &cancellables)
        
        // 3. HealthKit 42일 과거 데이터로부터 순토 CTL / ATL / TSB 정밀 계산 엔진 연결
        healthKitManager.$past42DaysWorkouts
            .sink { [weak self] workouts in
                guard let self = self else { return }
                if !workouts.isEmpty {
                    let calculated = self.trainingLoadCalculator.calculateTrainingLoad(from: workouts)
                    self.trainingLoad = calculated
                }
            }
            .store(in: &cancellables)
        
        // 백그라운드 추적 시작
        Task {
            await stepCoordinator.startTracking()
        }
    }
    
    // MARK: - 목표 100% 달성 감지 및 축하 트리거
    public func checkGoalAchievement() {
        guard !hasCelebratedToday && dailyGoal.targetRealSteps > 0 else { return }
        
        if stepBreakdown.realSteps >= dailyGoal.targetRealSteps {
            hasCelebratedToday = true
            
            if let index = badges.firstIndex(where: { $0.id == "real_10k_steps" }) {
                badges[index].isUnlocked = true
                badges[index].unlockedDate = Date()
                celebratedBadge = badges[index]
            } else {
                celebratedBadge = badges.first
            }
            
            if dailyGoal.isNotificationEnabled {
                NotificationManager.shared.sendGoalAchievedNotification(
                    goalTitle: "진짜 걸음 수 목표",
                    achievementValue: "\(stepBreakdown.realSteps) 걸음"
                )
            }
            
            showGoalCelebrationModal = true
        }
    }
    
    public func triggerTestCelebration() {
        hasCelebratedToday = false
        stepBreakdown.realSteps = dailyGoal.targetRealSteps + 250
        checkGoalAchievement()
    }
    
    // MARK: - 계산 프로퍼티 (달성률)
    public var realStepProgress: Double {
        guard dailyGoal.targetRealSteps > 0 else { return 0 }
        return Double(stepBreakdown.realSteps) / Double(dailyGoal.targetRealSteps)
    }
    
    public var remainingRealSteps: Int {
        max(0, dailyGoal.targetRealSteps - stepBreakdown.realSteps)
    }
    
    public var calorieProgress: Double {
        guard dailyGoal.targetCaloriesKcal > 0 else { return 0 }
        let currentCalories = recentWorkout?.caloriesBurnedKcal ?? 420
        return Double(currentCalories) / Double(dailyGoal.targetCaloriesKcal)
    }
    
    public var monthlyTotalWorkoutHours: Double {
        let totalSeconds = monthlyHistory.reduce(0.0) { $0 + $1.activeDurationSeconds }
        return totalSeconds / 3600.0
    }
    
    public func refreshDashboard() async {
        await stepCoordinator.refresh()
    }
}

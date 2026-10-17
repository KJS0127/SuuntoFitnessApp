import Foundation
import Combine

/// HealthKit과 CoreMotion을 통합 조율하여 '걸음 수 3단 분리'를 제공하는 코디네이터
@MainActor
public final class StepTrackingCoordinator: ObservableObject {
    public static let shared = StepTrackingCoordinator()
    
    private let healthKitManager = HealthKitManager.shared
    private let motionManager = MotionManager.shared
    
    @Published public var currentBreakdown: StepCountBreakdown = StepCountBreakdown()
    @Published public var isSyncing: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        bindSensors()
    }
    
    // MARK: - 센서 데이터 바인딩
    private func bindSensors() {
        // MotionManager의 '진짜 걸음' 업데이트 구독
        motionManager.$realStepsToday
            .sink { [weak self] realSteps in
                guard let self = self else { return }
                self.currentBreakdown.realSteps = max(self.currentBreakdown.realSteps, realSteps)
            }
            .store(in: &cancellables)
        
        // HealthKit의 '총 걸음' 및 '운동시 걸음' 업데이트 구독
        Publishers.CombineLatest(healthKitManager.$totalStepsToday, healthKitManager.$workoutStepsToday)
            .sink { [weak self] total, workout in
                guard let self = self else { return }
                self.currentBreakdown.totalSteps = total
                self.currentBreakdown.workoutSteps = workout
                
                // 만약 기기 센서 초기화 전이라면 HealthKit 총걸음의 88%를 진짜 걸음 기본치로 보정
                if self.currentBreakdown.realSteps == 0 && total > 0 {
                    self.currentBreakdown.realSteps = Int(Double(total) * 0.88)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 서비스 시작
    public func startTracking() async {
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. HealthKit 권한 요청 및 데이터 동기화
        do {
            try await healthKitManager.requestAuthorization()
        } catch {
            print("⚠️ HealthKit 권한 오류: \(error.localizedDescription)")
        }
        
        // 2. CoreMotion 실시간 보행 모니터링 시작
        motionManager.startPedometerUpdates()
    }
    
    // MARK: - 수동 새로고침
    public func refresh() async {
        isSyncing = true
        await healthKitManager.refreshAllData()
        isSyncing = false
    }
}

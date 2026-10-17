import Foundation
import CoreMotion
import Combine

/// CoreMotion CMPedometer 실시간 센서 매니저
@MainActor
public final class MotionManager: ObservableObject {
    public static let shared = MotionManager()
    
    private let pedometer = CMPedometer()
    private let filterEngine = RealStepFilterEngine.shared
    
    @Published public var isPedometerAvailable: Bool = false
    @Published public var rawStepsToday: Int = 0
    @Published public var realStepsToday: Int = 0
    @Published public var currentCadenceSpm: Double = 0.0
    @Published public var currentPaceSecondsPerMeter: Double? = nil
    
    private var lastRawPedometerStepCount: Int = 0
    
    private init() {
        self.isPedometerAvailable = CMPedometer.isStepCountingAvailable()
    }
    
    // MARK: - 실시간 Pedometer 추적 시작
    public func startPedometerUpdates() {
        guard CMPedometer.isStepCountingAvailable() else {
            print("⚠️ CMPedometer를 이 기기에서 사용할 수 없습니다.")
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        lastRawPedometerStepCount = 0
        
        // 1. 오늘 0시부터 현재까지의 과거 데이터를 먼저 조회하여 기준치 복원
        pedometer.queryPedometerData(from: startOfDay, to: Date()) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            Task { @MainActor in
                let steps = data.numberOfSteps.intValue
                self?.rawStepsToday = steps
                self?.lastRawPedometerStepCount = steps
                // 과거 데이터는 약 85~90%를 유효 걸음으로 초기 보정
                let estimatedReal = Int(Double(steps) * 0.88)
                self?.filterEngine.reset(initialSteps: estimatedReal)
                self?.realStepsToday = estimatedReal
            }
        }
        
        // 2. 실시간 라이브 업데이트 수신
        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            
            Task { @MainActor in
                let currentTotal = data.numberOfSteps.intValue
                let delta = max(0, currentTotal - self.lastRawPedometerStepCount)
                self.lastRawPedometerStepCount = currentTotal
                self.rawStepsToday = currentTotal
                
                // CMPedometer cadence는 초당 걸음 수(steps/sec)이므로 x60 하여 spm으로 변환
                let spm = (data.currentCadence?.doubleValue ?? 0.0) * 60.0
                self.currentCadenceSpm = spm
                self.currentPaceSecondsPerMeter = data.currentPace?.doubleValue
                
                // 정밀 필터링 엔진 통과
                let updatedRealSteps = self.filterEngine.processPedometerUpdate(
                    rawStepDelta: delta,
                    cadenceSpm: spm,
                    timestamp: data.endDate
                )
                self.realStepsToday = updatedRealSteps
            }
        }
    }
    
    // MARK: - 추적 중지
    public func stopPedometerUpdates() {
        pedometer.stopUpdates()
    }
}

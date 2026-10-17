import Foundation
import CoreMotion
import Combine

/// '진짜 걸음 수' 판별 및 필터링 엔진
/// - 규칙: 60 spm 이상의 유효 보행 케이던스가 최소 15초 이상 유지될 때만 유효 걸음으로 인정
public final class RealStepFilterEngine: @unchecked Sendable {
    public static let shared = RealStepFilterEngine()
    
    // 필터링 임계치 설정
    public let minimumCadenceSpm: Double = 60.0 // 분당 최소 60보
    public let minimumSustainedSeconds: TimeInterval = 15.0 // 최소 15초 지속
    
    // 상태 추적
    private var isWalkingWindowActive: Bool = false
    private var windowStartTime: Date? = nil
    private var bufferedStepsInCurrentWindow: Int = 0
    private var accumulatedRealSteps: Int = 0
    
    private let lock = NSLock()
    
    private init() {}
    
    /// 새 보행 패킷 입력 및 실시간 필터링
    /// - Parameters:
    ///   - newRawSteps: 이전 업데이트 이후 감지된 원시 걸음 수 증가분
    ///   - currentCadence: 현재 측정된 케이던스 (steps per second or steps per minute)
    ///   - timestamp: 감지 시각
    /// - Returns: 지금까지 확정된 누적 '진짜 걸음 수'
    public func processPedometerUpdate(
        rawStepDelta: Int,
        cadenceSpm: Double?,
        timestamp: Date = Date()
    ) -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        let validCadence = (cadenceSpm ?? 0) >= minimumCadenceSpm
        
        if validCadence {
            if !isWalkingWindowActive {
                // 새로운 보행 윈도우 시작
                isWalkingWindowActive = true
                windowStartTime = timestamp
                bufferedStepsInCurrentWindow = rawStepDelta
            } else {
                // 이미 보행 중인 상태에서 걸음 수 버퍼링
                bufferedStepsInCurrentWindow += rawStepDelta
                
                // 보행 시작 후 최소 지속 시간(15초)을 통과했는지 확인
                if let start = windowStartTime, timestamp.timeIntervalSince(start) >= minimumSustainedSeconds {
                    // 유효 보행 조건 달성 -> 버퍼에 있던 걸음을 진짜 걸음으로 확정
                    accumulatedRealSteps += bufferedStepsInCurrentWindow
                    bufferedStepsInCurrentWindow = 0 // 버퍼 비우기
                }
            }
        } else {
            // 유효 케이던스 미달 (멈춤, 차량 탑승, 가벼운 잔여 진동)
            if isWalkingWindowActive {
                // 15초를 못 채우고 멈춘 경우 -> 버퍼에 저장된 걸음은 '단발성 진동 노이즈'로 판단하여 폐기
                isWalkingWindowActive = false
                windowStartTime = nil
                bufferedStepsInCurrentWindow = 0
            }
        }
        
        return accumulatedRealSteps
    }
    
    /// 일일 초기화 (자정 또는 새 세션 시작 시)
    public func reset(initialSteps: Int = 0) {
        lock.lock()
        defer { lock.unlock() }
        accumulatedRealSteps = initialSteps
        bufferedStepsInCurrentWindow = 0
        windowStartTime = nil
        isWalkingWindowActive = false
    }
    
    /// 현재까지 누적된 진짜 걸음 수 반환
    public var currentRealSteps: Int {
        lock.lock()
        defer { lock.unlock() }
        return accumulatedRealSteps
    }
}

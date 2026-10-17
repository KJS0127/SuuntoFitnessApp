import XCTest
@testable import SuuntoFitnessApp

final class StepFilteringTests: XCTestCase {
    var engine: RealStepFilterEngine!
    
    override func setUp() {
        super.setUp()
        engine = RealStepFilterEngine.shared
        engine.reset(initialSteps: 0)
    }
    
    // MARK: - Test 1: 60 spm 미만 단발성 진동/흔들림은 누적에서 제외
    func testLowCadenceStepsAreIgnored() {
        let startTime = Date()
        
        // 분당 45보(저케이던스 - 단순 손흔들림 또는 차량 정차 잔진동)로 20걸음 발생
        let realSteps = engine.processPedometerUpdate(
            rawStepDelta: 20,
            cadenceSpm: 45.0,
            timestamp: startTime
        )
        
        XCTAssertEqual(realSteps, 0, "60 spm 미만의 케이던스는 진짜 걸음으로 인정되지 않아야 합니다.")
        XCTAssertEqual(engine.currentRealSteps, 0)
    }
    
    // MARK: - Test 2: 60 spm 이상이지만 15초 미만으로 멈춘 경우 (단발성 움직임) 폐기
    func testHighCadenceUnder15SecondsIsDropped() {
        let startTime = Date()
        
        // 1. 유효 케이던스(110 spm)로 걸음 시작 (0초 시점, 8걸음)
        _ = engine.processPedometerUpdate(
            rawStepDelta: 8,
            cadenceSpm: 110.0,
            timestamp: startTime
        )
        // 15초가 지나기 전이므로 아직 확정치로 반영되지 않음
        XCTAssertEqual(engine.currentRealSteps, 0, "15초 이전에는 버퍼링 중이므로 확정 걸음 수가 0이어야 합니다.")
        
        // 2. 8초 후 보행 멈춤 (케이던스 0)
        let stopped = engine.processPedometerUpdate(
            rawStepDelta: 0,
            cadenceSpm: 0.0,
            timestamp: startTime.addingTimeInterval(8.0)
        )
        
        // 15초 미만이므로 버퍼의 걸음이 폐기되어야 함
        XCTAssertEqual(stopped, 0, "15초 미만 단발성 움직임은 버퍼에서 자동 폐기되어 누적되지 않아야 합니다.")
    }
    
    // MARK: - Test 3: 60 spm 이상 + 15초 이상 연속 보행 시 진짜 걸음으로 확정 누적
    func testValidSustainedWalkingIsAccumulated() {
        let startTime = Date()
        
        // 0초: 120 spm으로 10걸음 발생
        _ = engine.processPedometerUpdate(
            rawStepDelta: 10,
            cadenceSpm: 120.0,
            timestamp: startTime
        )
        
        // 10초 경과: 120 spm으로 추가 15걸음 발생
        _ = engine.processPedometerUpdate(
            rawStepDelta: 15,
            cadenceSpm: 120.0,
            timestamp: startTime.addingTimeInterval(10.0)
        )
        XCTAssertEqual(engine.currentRealSteps, 0, "10초 시점에는 아직 15초 미달이므로 0이어야 합니다.")
        
        // 16초 경과: 120 spm으로 추가 12걸음 발생 (15초 돌파!)
        let confirmedSteps = engine.processPedometerUpdate(
            rawStepDelta: 12,
            cadenceSpm: 120.0,
            timestamp: startTime.addingTimeInterval(16.0)
        )
        
        // 10 + 15 + 12 = 37걸음이 모두 진짜 걸음으로 확정 반영되어야 함
        XCTAssertEqual(confirmedSteps, 37, "15초 이상 유지 시 버퍼에 모인 모든 걸음(37보)이 일괄 확정되어야 합니다.")
        XCTAssertEqual(engine.currentRealSteps, 37)
    }
    
    // MARK: - Test 4: 3단 걸음 수 모델의 독립성 검증
    func testStepCountBreakdownIntegrity() {
        let breakdown = StepCountBreakdown(totalSteps: 10000, realSteps: 8500, workoutSteps: 4500)
        
        XCTAssertGreaterThanOrEqual(breakdown.totalSteps, breakdown.realSteps, "전체 걸음 수는 항상 진짜 걸음 수보다 크거나 같아야 합니다.")
        XCTAssertGreaterThanOrEqual(breakdown.realSteps, breakdown.workoutSteps, "진짜 걸음 수는 운동 세션 걸음 수보다 크거나 같아야 합니다.")
    }
}

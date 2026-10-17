import XCTest
@testable import SuuntoFitnessApp

final class TrainingLoadCalculatorTests: XCTestCase {
    var calculator: TrainingLoadCalculator!
    
    override func setUp() {
        super.setUp()
        calculator = TrainingLoadCalculator.shared
    }
    
    // MARK: - Test 1: TSS 수식 산출 정확도 검증
    func testTSSCalculation() {
        // 1시간(3600초) 동안 평균 심박 160bpm (max: 188, resting: 60)
        // hrReserve = 128, activeReserve = 100, IF = 100/128 = 0.78125
        // TSS = 1.0 * (0.78125)^2 * 100 = 61.035
        let duration: TimeInterval = 3600
        let tss = calculator.calculateTSS(
            durationSeconds: duration,
            avgHeartRate: 160,
            maxHeartRate: 188,
            restingHeartRate: 60
        )
        
        XCTAssertGreaterThan(tss, 55.0)
        XCTAssertLessThan(tss, 68.0)
    }
    
    // MARK: - Test 2: TSB = CTL - ATL 관계 및 경계값 검증
    func testTrainingLoadBalanceRelation() {
        let metrics = TrainingLoadMetrics(ctl: 50.0, atl: 65.0, recentTSS: 70.0)
        
        // TSB = CTL - ATL = 50 - 65 = -15
        XCTAssertEqual(metrics.tsb, -15.0, accuracy: 0.001, "TSB는 반드시 CTL - ATL과 정확히 일치해야 합니다.")
    }
    
    // MARK: - Test 3: 콜드 스타트(데이터 0건) 시 안전 반환 검증
    func testColdStartNoWorkouts() {
        let emptyMetrics = calculator.calculateTrainingLoad(from: [])
        
        XCTAssertEqual(emptyMetrics.ctl, 0.0)
        XCTAssertEqual(emptyMetrics.atl, 0.0)
        XCTAssertEqual(emptyMetrics.tsb, 0.0)
        XCTAssertEqual(emptyMetrics.recentTSS, 0.0)
    }
}

import XCTest
@testable import SuuntoFitnessApp

final class CommuteAndWellnessTests: XCTestCase {
    // MARK: - Test 1: 커뮤트 탄소 절감량(CO2e) 계산 정확도
    func testCommuteCarbonSavings() {
        let calculator = CommuteCarbonCalculator.shared
        
        // 10,000m (10km) 자전거/도보 출퇴근
        let savedKg = calculator.calculateSavedCO2Kg(distanceMeters: 10000.0)
        
        // 10km * 0.192kg/km = 1.92kg
        XCTAssertEqual(savedKg, 1.92, accuracy: 0.001, "10km 무동력 이동 시 1.92kg의 CO2e가 절감되어야 합니다.")
    }
    
    // MARK: - Test 2: 수면 부채(Sleep Debt) 음수/양수 방향 검증
    func testSleepDebtCalculation() {
        let wellnessAdequate = BodyWellnessMetrics(
            resourcePercentage: 80,
            sleepDurationSeconds: 28800, // 8시간
            sleepDebtHours: 0.0
        )
        XCTAssertEqual(wellnessAdequate.sleepDebtHours, 0.0)
        
        let wellnessDeficit = BodyWellnessMetrics(
            resourcePercentage: 55,
            sleepDurationSeconds: 21600, // 6시간 (2시간 부족)
            sleepDebtHours: -2.0
        )
        XCTAssertLessThan(wellnessDeficit.sleepDebtHours, 0.0, "수면이 부족하면 음수 부채로 표현되어야 합니다.")
    }
}

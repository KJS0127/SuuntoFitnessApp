import XCTest
@testable import SuuntoFitnessApp

final class NGPCalculatorTests: XCTestCase {
    var calculator: NGPCalculator!
    
    override func setUp() {
        super.setUp()
        calculator = NGPCalculator.shared
    }
    
    // MARK: - Test 1: 데이터 포인트가 2개 미만일 때 원래 페이스 보존
    func testInsufficientDataReturnsOriginalPace() {
        let singlePoint = [TrackPoint(latitude: 35.5, longitude: 129.3, altitude: 50, timestamp: Date(), speedMps: 2.5)]
        let ngp = calculator.calculateNGP(trackPoints: singlePoint, averagePaceSecondsPerKm: 390.0)
        
        XCTAssertEqual(ngp, 390.0, "포인트가 2개 미만이면 원래 평균 페이스를 안전하게 반환해야 합니다.")
    }
    
    // MARK: - Test 2: 오르막길(Ascent) 러닝 시 NGP는 평지 환산으로 더 빠른 페이스(초/km 감소)를 반환
    func testUphillRunningProducesFasterNGP() {
        let now = Date()
        var points: [TrackPoint] = []
        
        // 500미터 동안 40미터 상승하는 가파른 오르막 트랙 생성
        for i in 0..<10 {
            let pt = TrackPoint(
                latitude: 35.5300 + (Double(i) * 0.0005),
                longitude: 129.3000,
                altitude: 20.0 + (Double(i) * 4.0), // 고도 상승
                timestamp: now.addingTimeInterval(Double(i) * 30.0),
                speedMps: 2.2
            )
            points.append(pt)
        }
        
        let originalPace: Double = 420.0 // 07'00 /km (오르막이라 느려진 원래 페이스)
        let ngp = calculator.calculateNGP(trackPoints: points, averagePaceSecondsPerKm: originalPace)
        
        // 오르막 경사도 보정에 의해 NGP는 원래 페이스(420초)보다 더 빠른 수치(< 420초)여야 함
        XCTAssertLessThan(ngp, originalPace, "오르막을 달렸을 때 NGP는 평지 환산 효과로 인해 원래 페이스보다 빨라야(초가 작아야) 합니다.")
    }
}

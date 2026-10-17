import XCTest
import CoreLocation
@testable import SuuntoFitnessApp

@MainActor
final class LocationAutoPauseTests: XCTestCase {
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        locationManager = LocationManager.shared
    }
    
    // MARK: - Test 1: 고오차 GPS(20m 초과) 좌표 필터링 검증
    func testInaccurateLocationIsFilteredOut() {
        locationManager.startRunTracking()
        
        // 오차 45미터의 부정확한 GPS 위치 시뮬레이션
        let inaccurateLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.53, longitude: 129.30),
            altitude: 50,
            horizontalAccuracy: 45.0, // 기준치(20m) 초과
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [inaccurateLocation])
        
        XCTAssertEqual(locationManager.distanceMeters, 0.0, "오차가 20m를 초과하는 GPS 좌표는 누적 거리에 반영되지 않아야 합니다.")
        XCTAssertTrue(locationManager.recordedTrackPoints.isEmpty)
        
        _ = locationManager.stopRunTracking()
    }
    
    // MARK: - Test 2: 유효 속도로 이동 시 거리 및 트랙포인트 정상 누적
    func testValidMovementAccumulatesDistance() {
        locationManager.startRunTracking()
        
        let loc1 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.5300, longitude: 129.3000),
            altitude: 50,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 3.0,
            course: 0,
            speed: 2.8,
            timestamp: Date()
        )
        
        let loc2 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.5305, longitude: 129.3000),
            altitude: 51,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 3.0,
            course: 0,
            speed: 2.8,
            timestamp: Date().addingTimeInterval(10)
        )
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [loc1, loc2])
        
        XCTAssertGreaterThan(locationManager.distanceMeters, 30.0, "유효한 두 지점 간의 이동 거리가 정상적으로 누적되어야 합니다.")
        XCTAssertEqual(locationManager.recordedTrackPoints.count, 2)
        
        _ = locationManager.stopRunTracking()
    }
}

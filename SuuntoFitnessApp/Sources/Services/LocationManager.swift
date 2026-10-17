import Foundation
import CoreLocation
import Combine

/// 백그라운드 고정밀 GPS 위치 추적 및 실시간 러닝 메트릭 계산 매니저
@MainActor
public final class LocationManager: NSObject, ObservableObject {
    public static let shared = LocationManager()
    
    private let clManager = CLLocationManager()
    
    // 발행 상태 프로퍼티
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var isTracking: Bool = false
    @Published public var isAutoPaused: Bool = false
    @Published public var currentLocation: CLLocation? = nil
    @Published public var recordedTrackPoints: [TrackPoint] = []
    
    // 실시간 러닝 메트릭스
    @Published public var distanceMeters: Double = 0.0
    @Published public var durationSeconds: TimeInterval = 0.0
    @Published public var currentPaceSecondsPerKm: Double = 0.0
    @Published public var averagePaceSecondsPerKm: Double = 0.0
    @Published public var elevationGainMeters: Double = 0.0
    
    // 자동 일시정지 (Auto-Pause) 설정 임계치
    private let autoPauseSpeedThresholdMps: Double = 0.8 // 시속 약 2.9km 미만이면 정지로 간주
    private var lowSpeedDurationSeconds: TimeInterval = 0.0
    
    // 타이머 및 마지막 위치
    private var trackingTimer: Timer?
    private var lastValidLocation: CLLocation?
    private var lastAltitude: Double?
    
    override private init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        clManager.activityType = .fitness
        clManager.distanceFilter = 3.0 // 3미터마다 위치 갱신
        self.authorizationStatus = clManager.authorizationStatus
    }
    
    // MARK: - 위치 권한 요청
    public func requestLocationAuthorization() {
        clManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - 러닝 트래킹 시작
    public func startRunTracking() {
        // 데이터 초기화
        distanceMeters = 0.0
        durationSeconds = 0.0
        currentPaceSecondsPerKm = 0.0
        averagePaceSecondsPerKm = 0.0
        elevationGainMeters = 0.0
        recordedTrackPoints.removeAll()
        lastValidLocation = nil
        lastAltitude = nil
        isAutoPaused = false
        lowSpeedDurationSeconds = 0
        
        isTracking = true
        
        // 백그라운드 위치 추적 허용 설정 (iOS 기기 기준)
        #if os(iOS)
        clManager.allowsBackgroundLocationUpdates = true
        clManager.pausesLocationUpdatesAutomatically = false
        #endif
        
        clManager.startUpdatingLocation()
        startTimer()
    }
    
    // MARK: - 일시정지 및 재개
    public func togglePause() {
        if isTracking {
            isTracking = false
            stopTimer()
            clManager.stopUpdatingLocation()
        } else {
            isTracking = true
            isAutoPaused = false
            startTimer()
            clManager.startUpdatingLocation()
        }
    }
    
    // MARK: - 러닝 완료 및 트래킹 종료
    public func stopRunTracking() -> [TrackPoint] {
        isTracking = false
        isAutoPaused = false
        stopTimer()
        clManager.stopUpdatingLocation()
        return recordedTrackPoints
    }
    
    // MARK: - 타이머 루프
    private func startTimer() {
        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isTracking, !self.isAutoPaused else { return }
            self.durationSeconds += 1.0
            
            // 평균 페이스 계산 (전체 거리 > 50m 일 때)
            if self.distanceMeters > 50 {
                self.averagePaceSecondsPerKm = (self.durationSeconds / self.distanceMeters) * 1000.0
            }
        }
    }
    
    private func stopTimer() {
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for location in locations {
                // 1. 오차가 20미터 이상인 튀는 GPS 데이터 필터링
                guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 20.0 else {
                    continue
                }
                
                self.currentLocation = location
                
                guard self.isTracking else { continue }
                
                let speed = max(0, location.speed) // m/s
                
                // 2. 자동 일시정지 (Auto-Pause) 로직
                if speed < self.autoPauseSpeedThresholdMps {
                    self.lowSpeedDurationSeconds += 1.0
                    if self.lowSpeedDurationSeconds >= 10.0 && !self.isAutoPaused {
                        // 10초 이상 정지 상태면 자동 일시정지 전환
                        self.isAutoPaused = true
                    }
                } else {
                    // 다시 달리기 시작하면 자동 재개
                    self.lowSpeedDurationSeconds = 0.0
                    if self.isAutoPaused {
                        self.isAutoPaused = false
                    }
                }
                
                guard !self.isAutoPaused else { continue }
                
                // 3. 이동 거리 누적
                if let lastLoc = self.lastValidLocation {
                    let delta = location.distance(from: lastLoc)
                    if delta > 1.0 { // 최소 1m 이상 이동 시
                        self.distanceMeters += delta
                        
                        // 고도 상승 계산
                        if let lastAlt = self.lastAltitude {
                            let altDiff = location.altitude - lastAlt
                            if altDiff > 0.5 { // 0.5m 이상 상승 시
                                self.elevationGainMeters += altDiff
                            }
                        }
                    }
                }
                
                self.lastValidLocation = location
                self.lastAltitude = location.altitude
                
                // 4. 실시간 순간 페이스 계산 (속도 > 1.0 m/s 일 때)
                if speed > 1.0 {
                    self.currentPaceSecondsPerKm = 1000.0 / speed
                }
                
                // 5. 트랙 포인트 저장
                let point = TrackPoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    altitude: location.altitude,
                    timestamp: location.timestamp,
                    speedMps: speed
                )
                self.recordedTrackPoints.append(point)
            }
        }
    }
}

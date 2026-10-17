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
    
    // 비동기 타이머 태스크
    private var timerTask: Task<Void, Never>?
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
    
    // MARK: - Swift Concurrency 기반 안전한 타이머 루프
    private func startTimer() {
        stopTimer()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
                guard let self = self, self.isTracking, !self.isAutoPaused else { continue }
                self.durationSeconds += 1.0
                
                if self.distanceMeters > 50 {
                    self.averagePaceSecondsPerKm = (self.durationSeconds / self.distanceMeters) * 1000.0
                }
            }
        }
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    // 위치 업데이트 처리 내부 메서드
    public func handleLocationUpdates(_ locations: [CLLocation]) {
        for location in locations {
            guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 20.0 else {
                continue
            }
            
            self.currentLocation = location
            guard self.isTracking else { continue }
            
            let speed = max(0, location.speed)
            
            if speed < self.autoPauseSpeedThresholdMps {
                self.lowSpeedDurationSeconds += 1.0
                if self.lowSpeedDurationSeconds >= 10.0 && !self.isAutoPaused {
                    self.isAutoPaused = true
                }
            } else {
                self.lowSpeedDurationSeconds = 0.0
                if self.isAutoPaused {
                    self.isAutoPaused = false
                }
            }
            
            guard !self.isAutoPaused else { continue }
            
            if let lastLoc = self.lastValidLocation {
                let delta = location.distance(from: lastLoc)
                if delta > 1.0 {
                    self.distanceMeters += delta
                    if let lastAlt = self.lastAltitude {
                        let altDiff = location.altitude - lastAlt
                        if altDiff > 0.5 {
                            self.elevationGainMeters += altDiff
                        }
                    }
                }
            }
            
            self.lastValidLocation = location
            self.lastAltitude = location.altitude
            
            if speed > 1.0 {
                self.currentPaceSecondsPerKm = 1000.0 / speed
            }
            
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

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.handleLocationUpdates(locations)
        }
    }
}

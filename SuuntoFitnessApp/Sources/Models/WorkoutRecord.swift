import Foundation
import CoreLocation

// MARK: - 운동 종목 타입
public enum ActivityType: String, Codable, CaseIterable, Sendable {
    case running = "달리기"
    case cycling = "자전거"
    case walking = "걷기"
    case other = "기타"
    
    public var iconName: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .walking: return "figure.walk"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - 운동 후 컨디션/느낌 평가
public enum WorkoutFeeling: String, Codable, CaseIterable, Sendable {
    case excellent = "매우 좋음"
    case good = "좋음"
    case normal = "보통"
    case tired = "피곤함"
    case exhausted = "매우 힘듦"
    
    public var emoji: String {
        switch self {
        case .excellent: return "🤩"
        case .good: return "😊"
        case .normal: return "🙂"
        case .tired: return "😮‍💨"
        case .exhausted: return "🥵"
        }
    }
}

// MARK: - 위치 좌표 포인트
public struct TrackPoint: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var timestamp: Date
    public var speedMps: Double // m/s
    
    public init(latitude: Double, longitude: Double, altitude: Double, timestamp: Date, speedMps: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.speedMps = speedMps
    }
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - 날씨 및 환경 정보
public struct WorkoutWeather: Codable, Hashable, Sendable {
    public var temperatureCelsius: Double
    public var windSpeedMps: Double
    public var symbolName: String
    public var locationName: String
    
    public init(
        temperatureCelsius: Double = 11.0,
        windSpeedMps: Double = 3.0,
        symbolName: String = "sun.max.fill",
        locationName: String = "울산광역시"
    ) {
        self.temperatureCelsius = temperatureCelsius
        self.windSpeedMps = windSpeedMps
        self.symbolName = symbolName
        self.locationName = locationName
    }
}

// MARK: - 단일 운동 기록 세션 모델 (스크린샷 1번 상세 뷰 대응)
public struct WorkoutRecord: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var activityType: ActivityType
    public var startDate: Date
    public var endDate: Date
    public var deviceName: String // 예: Suunto Spartan Sport WHR / Apple Watch
    
    // 핵심 측정 지표
    public var durationSeconds: TimeInterval      // 지속 시간 (예: 32'42.10)
    public var distanceMeters: Double             // 거리 (예: 5010m -> 5.01km)
    public var averageHeartRateBpm: Int           // 평균 심박수 (예: 162 bpm)
    public var maxHeartRateBpm: Int               // 최고 심박수
    public var averagePaceSecondsPerKm: Double    // 평균 페이스 (초/km, 예: 392초 -> 06'32/km)
    public var ngpSecondsPerKm: Double            // NGP® (경사도 보정 페이스, 예: 380초 -> 06'20/km)
    public var elevationGainMeters: Double        // 상승 고도 (예: 51m)
    public var tss: Double                        // Training Stress Score (예: 58)
    public var cadenceSpm: Int                    // 평균 걸음 케이던스 (예: 167 spm)
    public var caloriesBurnedKcal: Int            // 소모 칼로리 (예: 836 kcal)
    
    // 환경 및 사용자 느낌
    public var feeling: WorkoutFeeling            // 느낌 평가
    public var weather: WorkoutWeather?           // 날씨
    public var achievements: [String]             // 달성 뱃지 문구 (예: "이 경로에서 두 번째로 빠른 시간")
    public var trackPoints: [TrackPoint]          // GPS 경로
    
    public init(
        id: UUID = UUID(),
        activityType: ActivityType = .running,
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(1962),
        deviceName: String = "Apple Watch Ultra",
        durationSeconds: TimeInterval = 1962.1,
        distanceMeters: Double = 5010,
        averageHeartRateBpm: Int = 162,
        maxHeartRateBpm: Int = 178,
        averagePaceSecondsPerKm: Double = 392,
        ngpSecondsPerKm: Double = 380,
        elevationGainMeters: Double = 51,
        tss: Double = 58,
        cadenceSpm: Int = 167,
        caloriesBurnedKcal: Int = 836,
        feeling: WorkoutFeeling = .good,
        weather: WorkoutWeather? = WorkoutWeather(),
        achievements: [String] = ["이 경로에서 두 번째로 빠른 시간", "2달 내 첫 번째 달리기"],
        trackPoints: [TrackPoint] = []
    ) {
        self.id = id
        self.activityType = activityType
        self.startDate = startDate
        self.endDate = endDate
        self.deviceName = deviceName
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.averageHeartRateBpm = averageHeartRateBpm
        self.maxHeartRateBpm = maxHeartRateBpm
        self.averagePaceSecondsPerKm = averagePaceSecondsPerKm
        self.ngpSecondsPerKm = ngpSecondsPerKm
        self.elevationGainMeters = elevationGainMeters
        self.tss = tss
        self.cadenceSpm = cadenceSpm
        self.caloriesBurnedKcal = caloriesBurnedKcal
        self.feeling = feeling
        self.weather = weather
        self.achievements = achievements
        self.trackPoints = trackPoints
    }
}

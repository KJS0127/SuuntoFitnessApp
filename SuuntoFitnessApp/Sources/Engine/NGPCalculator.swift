import Foundation

/// NGP® (Normalized Graded Pace - 경사도 보정 페이스) 계산 엔진
/// - 지형의 오르막과 내리막 경사도를 보정하여 평지 환산 페이스 산출
public final class NGPCalculator {
    public static let shared = NGPCalculator()
    
    private init() {}
    
    /// 트랙포인트 리스트로부터 정밀 NGP 계산 (초/km)
    public func calculateNGP(
        trackPoints: [TrackPoint],
        averagePaceSecondsPerKm: Double
    ) -> Double {
        guard trackPoints.count >= 2 else { return averagePaceSecondsPerKm }
        
        var totalEquivalentFlatSeconds: Double = 0.0
        var totalDistanceMeters: Double = 0.0
        
        for i in 1..<trackPoints.count {
            let prev = trackPoints[i - 1]
            let curr = trackPoints[i]
            
            // 두 점 사이의 수평 이동 거리 근사치
            let latDiff = (curr.latitude - prev.latitude) * 111000.0
            let lonDiff = (curr.longitude - prev.longitude) * 88000.0
            let segDist = sqrt(latDiff * latDiff + lonDiff * lonDiff)
            
            guard segDist > 1.0 else { continue }
            
            let altDiff = curr.altitude - prev.altitude
            let grade = altDiff / segDist // 경사도 (예: 0.05 = 5% 오르막)
            
            // Minetti 지형 비용 계수 근사치 C(grade)
            // 평지(grade = 0) 기준 계수 = 1.0
            let costFactor = 1.0 + (grade * 3.3)
            
            let dt = curr.timestamp.timeIntervalSince(prev.timestamp)
            // 평지 환산 시간: 오르막이면 더 적은 시간으로 환산(더 빠른 페이스 효과)
            let equivalentFlatSec = dt / max(0.5, costFactor)
            
            totalEquivalentFlatSeconds += equivalentFlatSec
            totalDistanceMeters += segDist
        }
        
        guard totalDistanceMeters > 50 else { return averagePaceSecondsPerKm }
        
        let ngpSecPerKm = (totalEquivalentFlatSeconds / totalDistanceMeters) * 1000.0
        // 지나친 왜곡 방지 범위 제한
        return min(averagePaceSecondsPerKm * 1.25, max(averagePaceSecondsPerKm * 0.82, ngpSecPerKm))
    }
}

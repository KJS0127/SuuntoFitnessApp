import Foundation

/// 출퇴근(Commute) 친환경 이산화탄소(CO2e) 절감량 계산 엔진
public final class CommuteCarbonCalculator {
    public static let shared = CommuteCarbonCalculator()
    
    // 평균 내연기관 승용차의 1km 주행 시 CO2e 배출량 (약 192g = 0.192kg)
    private let carEmissionKgPerKm: Double = 0.192
    
    private init() {}
    
    /// 무동력 이동 거리(미터)를 바탕으로 절감된 CO2e (kg) 계산
    public func calculateSavedCO2Kg(distanceMeters: Double) -> Double {
        let distanceKm = distanceMeters / 1000.0
        return distanceKm * carEmissionKgPerKm
    }
}

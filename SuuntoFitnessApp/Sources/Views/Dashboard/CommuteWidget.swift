import SwiftUI

// MARK: - 칼로리 & 상승 고도 위젯 (2열 그리드)
public struct CaloriesElevationWidget: View {
    public let caloriesKcal: Int
    public let targetCaloriesKcal: Int
    public let elevationMeters: Double
    
    public init(caloriesKcal: Int, targetCaloriesKcal: Int, elevationMeters: Double) {
        self.caloriesKcal = caloriesKcal
        self.targetCaloriesKcal = targetCaloriesKcal
        self.elevationMeters = elevationMeters
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // 칼로리 카드
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("칼로리")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(SuuntoTheme.textPrimary)
                        Text("오늘")
                            .font(.system(size: 11))
                            .foregroundColor(SuuntoTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(SuuntoTheme.accentOrange)
                }
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(caloriesKcal)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("kcal")
                        .font(.system(size: 11))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
                
                let diff = caloriesKcal - targetCaloriesKcal
                Text(diff >= 0 ? "목표 초과 달성!" : "목표 대비 \(diff) kcal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(diff >= 0 ? SuuntoTheme.accentGreen : SuuntoTheme.textTertiary)
            }
            .suuntoCard()
            
            // 상승 고도 카드
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("상승")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(SuuntoTheme.textPrimary)
                        Text("이번 주")
                            .font(.system(size: 11))
                            .foregroundColor(SuuntoTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(SuuntoTheme.accentGreen)
                }
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", elevationMeters))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("m")
                        .font(.system(size: 11))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
                
                Text("누적 획득 고도")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SuuntoTheme.textTertiary)
            }
            .suuntoCard()
        }
    }
}

// MARK: - 커뮤트(출퇴근) 탄소 절감 위젯
public struct CommuteWidget: View {
    public let metrics: CommuteMetrics
    
    public init(metrics: CommuteMetrics) {
        self.metrics = metrics
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("커뮤트")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("이번 달")
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "cloud.fill")
                    .font(.system(size: 16))
                    .foregroundColor(SuuntoTheme.accentGreen)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", metrics.co2SavedKg))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(SuuntoTheme.textPrimary)
                Text("kg CO₂e 줄임")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(SuuntoTheme.textSecondary)
            }
            
            // 종목 아이콘 뱃지
            HStack(spacing: 12) {
                CommuteBadge(icon: "bicycle", count: metrics.bikeCount)
                CommuteBadge(icon: "figure.run", count: metrics.runCount)
                CommuteBadge(icon: "figure.walk", count: metrics.walkCount)
            }
        }
        .suuntoCard()
    }
}

private struct CommuteBadge: View {
    let icon: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(SuuntoTheme.textSecondary)
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(SuuntoTheme.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(white: 0.16))
        .clipShape(Capsule())
    }
}

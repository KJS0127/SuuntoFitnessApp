import SwiftUI

public struct StepCountWidget: View {
    public let breakdown: StepCountBreakdown
    public let targetRealSteps: Int
    public let progress: Double
    
    public init(breakdown: StepCountBreakdown, targetRealSteps: Int, progress: Double) {
        self.breakdown = breakdown
        self.targetRealSteps = targetRealSteps
        self.progress = progress
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("걸음 수")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("오늘 (진짜 걸음 기준)")
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 20))
                    .foregroundColor(SuuntoTheme.accentBlue)
            }
            
            // 핵심 수치 (진짜 걸음 수)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(breakdown.realSteps)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("/ \(targetRealSteps) 보")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
                
                // 목표까지 남은 보수 문구
                let remaining = max(0, targetRealSteps - breakdown.realSteps)
                Text(remaining > 0 ? "목표까지 -\(remaining) 걸음" : "🎉 오늘 목표 달성 완료!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(remaining > 0 ? SuuntoTheme.textSecondary : SuuntoTheme.accentGreen)
            }
            
            // 프로그레스 바 게이지
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.18))
                        .frame(height: 7)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [SuuntoTheme.accentBlue, SuuntoTheme.accentGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(geo.size.width * CGFloat(progress), geo.size.width), height: 7)
                }
            }
            .frame(height: 7)
            
            // 3단 걸음 수 상세 그리드 (전체 / 진짜 / 운동시)
            HStack(spacing: 8) {
                StepSubPill(
                    title: "전체 걸음",
                    value: "\(breakdown.totalSteps)",
                    color: SuuntoTheme.textSecondary
                )
                StepSubPill(
                    title: "진짜 걸음",
                    value: "\(breakdown.realSteps)",
                    color: SuuntoTheme.accentBlue
                )
                StepSubPill(
                    title: "운동 시",
                    value: "\(breakdown.workoutSteps)",
                    color: SuuntoTheme.accentYellow
                )
            }
        }
        .suuntoCard()
    }
}

private struct StepSubPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(SuuntoTheme.textTertiary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(white: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ZStack {
        SuuntoTheme.background.ignoresSafeArea()
        StepCountWidget(
            breakdown: MockFitnessData.sampleSteps,
            targetRealSteps: 10000,
            progress: 0.98
        )
        .padding()
    }
}

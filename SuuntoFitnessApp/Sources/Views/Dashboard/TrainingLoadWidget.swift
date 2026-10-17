import SwiftUI

public struct TrainingLoadWidget: View {
    public let metrics: TrainingLoadMetrics
    
    public init(metrics: TrainingLoadMetrics) {
        self.metrics = metrics
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("오늘")
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "forward.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(SuuntoTheme.accentRed)
                    .clipShape(Circle())
            }
            
            // 설명 문구
            Text("운동을 추적하여 체력과 피로도 인사이트를 얻으세요.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(SuuntoTheme.textSecondary)
                .lineLimit(2)
            
            // 3단 지표 (CTL / ATL / TSB)
            HStack(spacing: 12) {
                MetricColumn(title: "CTL (체력)", value: String(format: "%.0f", metrics.ctl), color: SuuntoTheme.accentBlue)
                Divider().background(Color(white: 0.2))
                MetricColumn(title: "ATL (피로)", value: String(format: "%.0f", metrics.atl), color: SuuntoTheme.accentRed)
                Divider().background(Color(white: 0.2))
                MetricColumn(title: "TSB (컨디션)", value: String(format: "%+.0f", metrics.tsb), color: metrics.tsb >= 0 ? SuuntoTheme.accentGreen : SuuntoTheme.accentYellow)
            }
            .frame(height: 48)
        }
        .suuntoCard()
    }
}

private struct MetricColumn: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(SuuntoTheme.textTertiary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        SuuntoTheme.background.ignoresSafeArea()
        TrainingLoadWidget(metrics: MockFitnessData.sampleTrainingLoad)
            .padding()
    }
}

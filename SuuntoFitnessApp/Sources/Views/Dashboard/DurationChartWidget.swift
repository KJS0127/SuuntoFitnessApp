import SwiftUI
import Charts

public struct DurationChartWidget: View {
    public let title: String
    public let subtitle: String
    public let totalHours: Double
    public let history: [DailyActivitySummary]
    public let accentColor: Color
    public let iconName: String
    
    public init(
        title: String = "지속 시간",
        subtitle: String = "이번 달",
        totalHours: Double,
        history: [DailyActivitySummary],
        accentColor: Color = SuuntoTheme.accentYellow,
        iconName: String = "figure.run"
    ) {
        self.title = title
        self.subtitle = subtitle
        self.totalHours = totalHours
        self.history = history
        self.accentColor = accentColor
        self.iconName = iconName
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
                Spacer()
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(accentColor)
                    .clipShape(Circle())
            }
            
            // 총 시간
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", totalHours))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(SuuntoTheme.textPrimary)
                Text("시간")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SuuntoTheme.textSecondary)
            }
            
            // 막대 차트
            Chart(history) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Hours", item.activeDurationSeconds / 3600.0)
                )
                .foregroundStyle(item.hasCompletedWorkout ? accentColor : Color(white: 0.22))
                .cornerRadius(2)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(dateFormatted(date))
                                .font(.system(size: 9))
                                .foregroundColor(SuuntoTheme.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 55)
        }
        .suuntoCard()
    }
    
    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        return formatter.string(from: date)
    }
}

#Preview {
    ZStack {
        SuuntoTheme.background.ignoresSafeArea()
        DurationChartWidget(
            totalHours: 18.5,
            history: MockFitnessData.sampleMonthlyHistory
        )
        .padding()
    }
}

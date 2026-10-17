import SwiftUI

public struct ActivityGrassWidget: View {
    public let history: [DailyActivitySummary]
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    
    public init(history: [DailyActivitySummary]) {
        self.history = history
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 헤더
            HStack {
                Text("최근 30일")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(SuuntoTheme.textPrimary)
                Spacer()
                Text("\(completedWorkoutDays)일 달성")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SuuntoTheme.accentGreen)
            }
            
            // 요일 헤더
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SuuntoTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 7열 도트 매트릭스 (잔디)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(history.suffix(28)) { item in
                    Circle()
                        .fill(item.hasCompletedWorkout ? SuuntoTheme.accentGreen : Color(white: 0.22))
                        .frame(width: 8, height: 8)
                        .overlay(
                            item.hasCompletedWorkout ?
                            Circle().stroke(SuuntoTheme.accentGreen.opacity(0.4), lineWidth: 3) : nil
                        )
                }
            }
            .padding(.top, 4)
        }
        .suuntoCard()
    }
    
    private var completedWorkoutDays: Int {
        history.filter { $0.hasCompletedWorkout }.count
    }
}

#Preview {
    ZStack {
        SuuntoTheme.background.ignoresSafeArea()
        ActivityGrassWidget(history: MockFitnessData.sampleMonthlyHistory)
            .padding()
    }
}

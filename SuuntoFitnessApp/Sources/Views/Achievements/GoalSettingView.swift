import SwiftUI

/// 일일 운동 목표 커스텀 설정 모달 뷰
public struct GoalSettingView: View {
    @Binding public var goal: DailyGoal
    @Environment(\.dismiss) private var dismiss
    
    public init(goal: Binding<DailyGoal>) {
        self._goal = goal
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("매일 달성하고자 하는 운동 목표를 설정하세요. 진짜 걸음 수와 활동량을 기준으로 정밀하게 측정됩니다.")
                        .font(.system(size: 13))
                        .foregroundColor(SuuntoTheme.textSecondary)
                        .padding(.top, 4)
                    
                    // 1. 일일 진짜 걸음 수 목표
                    GoalSliderCard(
                        title: "진짜 걸음 수 목표",
                        icon: "figure.walk",
                        iconColor: SuuntoTheme.accentBlue,
                        valueText: "\(goal.targetRealSteps) 걸음",
                        value: Binding(
                            get: { Double(goal.targetRealSteps) },
                            set: { goal.targetRealSteps = Int($0) }
                        ),
                        range: 4000...20000,
                        step: 500
                    )
                    
                    // 2. 일일 활동 칼로리 목표
                    GoalSliderCard(
                        title: "활동 칼로리 목표",
                        icon: "flame.fill",
                        iconColor: SuuntoTheme.accentOrange,
                        valueText: "\(goal.targetCaloriesKcal) kcal",
                        value: Binding(
                            get: { Double(goal.targetCaloriesKcal) },
                            set: { goal.targetCaloriesKcal = Int($0) }
                        ),
                        range: 200...1200,
                        step: 50
                    )
                    
                    // 3. 일일 운동 시간 목표
                    GoalSliderCard(
                        title: "운동 시간 목표",
                        icon: "stopwatch.fill",
                        iconColor: SuuntoTheme.accentGreen,
                        valueText: "\(Int(goal.targetActiveTimeSeconds / 60)) 분",
                        value: Binding(
                            get: { goal.targetActiveTimeSeconds / 60 },
                            set: { goal.targetActiveTimeSeconds = $0 * 60 }
                        ),
                        range: 15...120,
                        step: 5
                    )
                    
                    // 4. 알림 설정 토글 카드
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $goal.isNotificationEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(SuuntoTheme.accentYellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("목표 달성 푸시 알림")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(SuuntoTheme.textPrimary)
                                    Text("100% 달성 시 즉시 축하 알림 발송")
                                        .font(.system(size: 12))
                                        .foregroundColor(SuuntoTheme.textSecondary)
                                }
                            }
                        }
                        .tint(SuuntoTheme.accentYellow)
                    }
                    .suuntoCard()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(SuuntoTheme.background)
            .navigationTitle("일일 운동 목표 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        HapticManager.shared.mediumImpact()
                        if goal.isNotificationEnabled {
                            Task {
                                _ = await NotificationManager.shared.requestAuthorization()
                                NotificationManager.shared.scheduleEveningReminder(targetSteps: goal.targetRealSteps)
                            }
                        }
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(SuuntoTheme.accentYellow)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

private struct GoalSliderCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(SuuntoTheme.textPrimary)
                Spacer()
                Text(valueText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(iconColor)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(iconColor)
        }
        .suuntoCard()
    }
}

#Preview {
    GoalSettingView(goal: .constant(MockFitnessData.sampleDailyGoal))
}

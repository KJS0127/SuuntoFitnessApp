import SwiftUI

public struct DashboardView: View {
    @ObservedObject public var viewModel: DashboardViewModel
    
    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // '위젯' 섹션 타이틀
                Text("위젯")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(SuuntoTheme.textPrimary)
                    .padding(.top, 8)
                
                // 1. 걸음 수 3단 분리 및 목표 카드 (메인)
                StepCountWidget(
                    breakdown: viewModel.stepBreakdown,
                    targetRealSteps: viewModel.dailyGoal.targetRealSteps,
                    progress: viewModel.realStepProgress
                )
                
                // 2. 최근 활동 미니 맵 위젯 (탭 시 러닝 결과 상세로 이동)
                MiniMapWidget(workout: viewModel.recentWorkout) {
                    viewModel.showWorkoutDetail = true
                }
                
                // 3. 월간 운동 지속 시간 차트
                DurationChartWidget(
                    title: "지속 시간",
                    subtitle: "이번 달",
                    totalHours: viewModel.monthlyTotalWorkoutHours,
                    history: viewModel.monthlyHistory,
                    accentColor: SuuntoTheme.accentYellow,
                    iconName: "figure.run"
                )
                
                // 4. 칼로리 & 상승 고도 (2열 카드)
                CaloriesElevationWidget(
                    caloriesKcal: viewModel.recentWorkout?.caloriesBurnedKcal ?? 450,
                    targetCaloriesKcal: viewModel.dailyGoal.targetCaloriesKcal,
                    elevationMeters: viewModel.recentWorkout?.elevationGainMeters ?? 51.0
                )
                
                // 5. 순토 Progress (훈련 부하: CTL, ATL, TSB)
                TrainingLoadWidget(metrics: viewModel.trainingLoad)
                
                // 6. 신체 리소스 (바디 배터리)
                BodyResourceWidget(resourcePercentage: viewModel.wellness.resourcePercentage)
                
                // 7. 수면 분석 위젯
                SleepWidget(
                    durationSeconds: viewModel.wellness.sleepDurationSeconds,
                    sleepDebtHours: viewModel.wellness.sleepDebtHours
                )
                
                // 8. 심박수 & HRV
                HeartRateWellnessWidget(
                    heartRate: viewModel.wellness.currentHeartRate,
                    hrvSDNN: viewModel.wellness.hrvSDNN
                )
                
                // 9. 최근 30일 잔디 매트릭스
                ActivityGrassWidget(history: viewModel.monthlyHistory)
                
                // 10. 커뮤트 탄소 절감 위젯
                CommuteWidget(metrics: viewModel.commute)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
        .background(SuuntoTheme.background)
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel())
        .preferredColorScheme(.dark)
}

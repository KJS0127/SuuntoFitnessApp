import SwiftUI

public struct MainTabView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showLiveTracker: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                SuuntoTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - 1. 상단 앱바 헤더 (정수's 운동)
                    HStack(spacing: 12) {
                        // 워치 상태 및 앱 이름
                        HStack(spacing: 8) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "applewatch")
                                    .font(.system(size: 20))
                                    .foregroundColor(SuuntoTheme.textPrimary)
                                
                                if viewModel.isWatchConnected {
                                    Circle()
                                        .fill(SuuntoTheme.accentYellow)
                                        .frame(width: 7, height: 7)
                                        .offset(x: 2, y: -2)
                                }
                            }
                            
                            // 앱 이름 표기
                            Text("정수's 운동")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(SuuntoTheme.textPrimary)
                            
                            // 목표 설정 버튼
                            Button(action: {
                                HapticManager.shared.lightImpact()
                                viewModel.showGoalSettingSheet = true
                            }) {
                                Image(systemName: "target")
                                    .font(.system(size: 15))
                                    .foregroundColor(SuuntoTheme.accentYellow)
                            }
                        }
                        
                        Spacer()
                        
                        // 빠른 액션: 배지 보관함(왕관), 러닝 시작(+), 알림 테스트(종)
                        HStack(spacing: 10) {
                            // 배지 보관함 버튼
                            Button(action: {
                                HapticManager.shared.lightImpact()
                                viewModel.showBadgeCollectionSheet = true
                            }) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(SuuntoTheme.accentYellow)
                                    .padding(8)
                                    .background(Color(white: 0.22))
                                    .clipShape(Circle())
                            }
                            
                            // 러닝 트래킹 시작 버튼 (+)
                            Button(action: {
                                HapticManager.shared.mediumImpact()
                                showLiveTracker = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(SuuntoTheme.accentYellow.opacity(0.85))
                                    .clipShape(Circle())
                            }
                            
                            // 알림 테스트 버튼 (종)
                            Button(action: {
                                HapticManager.shared.lightImpact()
                                viewModel.triggerTestCelebration()
                            }) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color(white: 0.22))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                    
                    // MARK: - 2. 세그먼트 탭 바 [대시보드 | 활동]
                    HStack(spacing: 24) {
                        ForEach(DashboardViewModel.ActiveTab.allCases, id: \.self) { tab in
                            Button(action: {
                                HapticManager.shared.lightImpact()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.selectedTab = tab
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 16, weight: viewModel.selectedTab == tab ? .bold : .medium))
                                        .foregroundColor(viewModel.selectedTab == tab ? SuuntoTheme.textPrimary : SuuntoTheme.textTertiary)
                                    
                                    // 하단 인디케이터 라인
                                    Rectangle()
                                        .fill(viewModel.selectedTab == tab ? SuuntoTheme.accentBlue : Color.clear)
                                        .frame(height: 2.5)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    
                    Divider().background(Color(white: 0.15))
                    
                    // MARK: - 3. 선택된 탭 컨텐츠 뷰
                    if viewModel.selectedTab == .dashboard {
                        DashboardView(viewModel: viewModel)
                    } else {
                        ActivitiesListView(viewModel: viewModel)
                    }
                }
                
                // MARK: - 4. 목표 100% 달성 전체 화면 축하 모달 오버레이
                if viewModel.showGoalCelebrationModal, let badge = viewModel.celebratedBadge {
                    GoalCelebrationModalView(
                        badge: badge,
                        achievedText: "오늘 진짜 걸음 \(viewModel.stepBreakdown.realSteps)보를 완수하셨습니다!"
                    ) {
                        withAnimation {
                            viewModel.showGoalCelebrationModal = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            .fullScreenCover(isPresented: $showLiveTracker) {
                LiveRunningTrackerView { completedRecord in
                    viewModel.recentWorkout = completedRecord
                    viewModel.stepBreakdown.workoutSteps += completedRecord.cadenceSpm * Int(completedRecord.durationSeconds / 60)
                    viewModel.stepBreakdown.realSteps += completedRecord.cadenceSpm * Int(completedRecord.durationSeconds / 60)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showWorkoutDetail = true
                    }
                }
            }
            .sheet(isPresented: $viewModel.showWorkoutDetail) {
                if let workout = viewModel.recentWorkout {
                    RunDetailView(record: workout)
                }
            }
            .sheet(isPresented: $viewModel.showGoalSettingSheet) {
                GoalSettingView(goal: $viewModel.dailyGoal)
            }
            .sheet(isPresented: $viewModel.showBadgeCollectionSheet) {
                NavigationStack {
                    BadgeCollectionView(badges: viewModel.badges)
                        .navigationTitle("업적 및 배지")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("닫기") {
                                    viewModel.showBadgeCollectionSheet = false
                                }
                                .foregroundColor(SuuntoTheme.accentYellow)
                            }
                        }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - '활동' 탭 서브 뷰
private struct ActivitiesListView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text("최근 기록")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(SuuntoTheme.textPrimary)
                    .padding(.top, 14)
                
                if let workout = viewModel.recentWorkout {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        viewModel.showWorkoutDetail = true
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .padding(10)
                                .background(SuuntoTheme.accentYellow)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("달리기 (\(workout.weather?.locationName ?? "야외 러닝"))")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(SuuntoTheme.textPrimary)
                                Text(String(format: "%d분 %d초 • %.2f km • 06'32 /km", Int(workout.durationSeconds) / 60, Int(workout.durationSeconds) % 60, workout.distanceMeters / 1000.0))
                                    .font(.system(size: 12))
                                    .foregroundColor(SuuntoTheme.textSecondary)
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(SuuntoTheme.textTertiary)
                        }
                        .suuntoCard()
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
        .background(SuuntoTheme.background)
    }
}

#Preview {
    MainTabView()
}

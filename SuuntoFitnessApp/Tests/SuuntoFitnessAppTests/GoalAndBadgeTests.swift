import XCTest
@testable import SuuntoFitnessApp

@MainActor
final class GoalAndBadgeTests: XCTestCase {
    var viewModel: DashboardViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = DashboardViewModel(
            stepBreakdown: StepCountBreakdown(totalSteps: 5000, realSteps: 4200, workoutSteps: 0),
            dailyGoal: DailyGoal(targetRealSteps: 10000, isNotificationEnabled: true)
        )
    }
    
    // MARK: - Test 1: 목표 미달성 시 프로그레스 및 모달 미표시 검증
    func testGoalUnderTarget() {
        XCTAssertFalse(viewModel.showGoalCelebrationModal)
        XCTAssertEqual(viewModel.realStepProgress, 0.42, accuracy: 0.01)
        XCTAssertEqual(viewModel.remainingRealSteps, 5800)
    }
    
    // MARK: - Test 2: 목표 100% 도달 시 달성 감지 및 축하 팝업 모달 활성화
    func testGoalAchievedTriggersModalAndBadge() {
        // 걸음 수를 10,200보로 증가
        viewModel.stepBreakdown.realSteps = 10200
        viewModel.checkGoalAchievement()
        
        XCTAssertTrue(viewModel.showGoalCelebrationModal, "목표치에 도달하면 축하 모달이 자동으로 활성화되어야 합니다.")
        XCTAssertGreaterThanOrEqual(viewModel.realStepProgress, 1.0)
        XCTAssertEqual(viewModel.remainingRealSteps, 0)
        
        // '진짜 10,000보 클럽' 배지가 해금되었는지 검증
        let tenKBadge = viewModel.badges.first { $0.id == "real_10k_steps" }
        XCTAssertNotNil(tenKBadge)
        XCTAssertTrue(tenKBadge?.isUnlocked ?? false, "목표 달성 시 해당 업적 배지가 해금되어야 합니다.")
    }
}

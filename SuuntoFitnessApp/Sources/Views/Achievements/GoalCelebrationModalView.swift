import SwiftUI

/// 일일 목표 100% 달성 전체 화면 축하 팝업 모달
public struct GoalCelebrationModalView: View {
    public let badge: AchievementBadge
    public let achievedText: String
    public let onDismiss: () -> Void
    
    @State private var badgeRotation: Double = -180
    @State private var badgeScale: CGFloat = 0.2
    @State private var showText: Bool = false
    
    public init(
        badge: AchievementBadge = AchievementBadge.standardBadges[1],
        achievedText: String = "오늘 진짜 걸음 10,000보를 완수하셨습니다!",
        onDismiss: @escaping () -> Void
    ) {
        self.badge = badge
        self.achievedText = achievedText
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // 반투명 다크 배경
            Color.black.opacity(0.88).ignoresSafeArea()
            
            // 컨페티(꽃가루 파티클)
            ConfettiView()
                .allowsHitTesting(false)
            
            VStack(spacing: 24) {
                Spacer()
                
                // 1. 3D 배지 회전 및 팝업 애니메이션
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [SuuntoTheme.accentYellow.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: badge.iconName)
                        .font(.system(size: 84))
                        .foregroundColor(SuuntoTheme.accentYellow)
                        .shadow(color: SuuntoTheme.accentYellow.opacity(0.6), radius: 18, x: 0, y: 0)
                        .rotation3DEffect(.degrees(badgeRotation), axis: (x: 0, y: 1, z: 0))
                        .scaleEffect(badgeScale)
                }
                
                // 2. 축하 타이틀 및 설명
                if showText {
                    VStack(spacing: 10) {
                        Text("목표 달성 완료! 🎉")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(badge.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(SuuntoTheme.accentYellow)
                        
                        Text(achievedText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(SuuntoTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        
                        Text(badge.description)
                            .font(.system(size: 13))
                            .foregroundColor(SuuntoTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                            .padding(.top, 4)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                
                // 3. 닫기 버튼
                Button(action: onDismiss) {
                    Text("확인 & 보관함에 저장")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SuuntoTheme.accentYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            // 햅틱 팡파레 실행
            HapticManager.shared.celebrationFanfare()
            
            // 배지 등장 애니메이션
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
                badgeScale = 1.0
                badgeRotation = 0
            }
            
            // 텍스트 등장
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showText = true
                }
            }
        }
    }
}

#Preview {
    GoalCelebrationModalView {}
}

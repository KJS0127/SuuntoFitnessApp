import SwiftUI

/// 업적 배지(게이미피케이션) 컬렉션 뷰
public struct BadgeCollectionView: View {
    public let badges: [AchievementBadge]
    @State private var selectedBadgeForDetail: AchievementBadge? = nil
    
    public init(badges: [AchievementBadge] = AchievementBadge.standardBadges) {
        self.badges = badges
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 요약 헤더
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("업적 및 배지")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(SuuntoTheme.textPrimary)
                        Text("운동 목표를 달성하고 나만의 배지를 수집해 보세요.")
                            .font(.system(size: 13))
                            .foregroundColor(SuuntoTheme.textSecondary)
                    }
                    Spacer()
                    
                    // 달성 수 뱃지
                    let unlockedCount = badges.filter { $0.isUnlocked }.count
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                        Text("\(unlockedCount) / \(badges.count)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(SuuntoTheme.accentYellow)
                    .clipShape(Capsule())
                }
                .padding(.top, 10)
                
                // 2열 배지 그리드
                let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(badges) { badge in
                        BadgeCell(badge: badge) {
                            HapticManager.shared.lightImpact()
                            selectedBadgeForDetail = badge
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(SuuntoTheme.background)
        .sheet(item: $selectedBadgeForDetail) { badge in
            GoalCelebrationModalView(
                badge: badge,
                achievedText: badge.isUnlocked ? "이미 달성 완료된 자랑스러운 배지입니다!" : "아직 잠겨 있는 배지입니다. 운동을 지속하여 해금해 보세요!"
            ) {
                selectedBadgeForDetail = nil
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct BadgeCell: View {
    let badge: AchievementBadge
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? SuuntoTheme.accentYellow.opacity(0.15) : Color(white: 0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: badge.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(badge.isUnlocked ? SuuntoTheme.accentYellow : Color(white: 0.35))
                    
                    if !badge.isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.black.opacity(0.8))
                            .clipShape(Circle())
                            .offset(x: 18, y: 18)
                    }
                }
                .padding(.top, 6)
                
                VStack(spacing: 4) {
                    Text(badge.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(badge.isUnlocked ? SuuntoTheme.textPrimary : SuuntoTheme.textTertiary)
                        .multilineTextAlignment(.center)
                    
                    Text(badge.description)
                        .font(.system(size: 11))
                        .foregroundColor(SuuntoTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(SuuntoTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(badge.isUnlocked ? SuuntoTheme.accentYellow.opacity(0.4) : SuuntoTheme.cardBorder.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BadgeCollectionView()
}

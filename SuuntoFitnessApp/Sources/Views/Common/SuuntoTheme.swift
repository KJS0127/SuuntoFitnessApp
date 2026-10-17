import SwiftUI

public enum SuuntoTheme {
    // MARK: - 컬러 팔레트 (순토 고유 올블랙 & 다크 그레이)
    public static let background = Color.black // #000000
    public static let cardSurface = Color(red: 0.10, green: 0.10, blue: 0.11) // #1A1A1C
    public static let cardBorder = Color(white: 0.18)
    
    // 브랜드 액센트 컬러
    public static let accentYellow = Color(red: 0.98, green: 0.82, blue: 0.28) // 러닝 앰버 노랑
    public static let accentGreen = Color(red: 0.35, green: 0.85, blue: 0.60)  // 리소스/지속시간 민트그린
    public static let accentRed = Color(red: 0.96, green: 0.32, blue: 0.38)    // 심박수/Progress 레드
    public static let accentBlue = Color(red: 0.30, green: 0.68, blue: 0.98)   // 탭/걸음수 스카이블루
    public static let accentPurple = Color(red: 0.70, green: 0.45, blue: 0.95) // 수면 퍼플
    public static let accentOrange = Color(red: 0.98, green: 0.55, blue: 0.25) // 칼로리 오렌지
    
    // 텍스트 컬러
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.65)
    public static let textTertiary = Color(white: 0.40)
    
    // 코너 반경
    public static let cardCornerRadius: CGFloat = 18.0
}

// MARK: - 순토 다크 카드 모디파이어
public struct SuuntoCardModifier: ViewModifier {
    public var padding: CGFloat = 16.0
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(SuuntoTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: SuuntoTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SuuntoTheme.cardCornerRadius, style: .continuous)
                    .stroke(SuuntoTheme.cardBorder.opacity(0.35), lineWidth: 1)
            )
    }
}

public extension View {
    func suuntoCard(padding: CGFloat = 16.0) -> some View {
        modifier(SuuntoCardModifier(padding: padding))
    }
}

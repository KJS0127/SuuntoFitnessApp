import SwiftUI

/// 순수 SwiftUI 기반 고성능 컨페티(꽃가루 파티클) 뷰
public struct ConfettiView: View {
    @State private var animate = false
    private let particleCount = 65
    
    public init() {}
    
    public var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { i in
                ConfettiParticle(index: i, animate: animate)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.5)) {
                animate = true
            }
        }
    }
}

private struct ConfettiParticle: View {
    let index: Int
    let animate: Bool
    
    // 파티클 속성 난수화
    private let startX: CGFloat = CGFloat.random(in: -50...50)
    private let targetX: CGFloat = CGFloat.random(in: -220...220)
    private let targetY: CGFloat = CGFloat.random(in: 120...600)
    private let rotation: Double = Double.random(in: 180...720)
    private let size: CGFloat = CGFloat.random(in: 7...13)
    private let color: Color = [
        SuuntoTheme.accentYellow,
        SuuntoTheme.accentGreen,
        SuuntoTheme.accentRed,
        SuuntoTheme.accentBlue,
        SuuntoTheme.accentPurple,
        SuuntoTheme.accentOrange
    ].randomElement()!
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: size, height: size * 1.5)
            .rotationEffect(.degrees(animate ? rotation : 0))
            .offset(x: animate ? targetX : startX, y: animate ? targetY : -80)
            .opacity(animate ? 0.0 : 1.0)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView()
    }
}

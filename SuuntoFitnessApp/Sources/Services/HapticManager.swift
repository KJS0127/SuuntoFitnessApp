#if canImport(UIKit)
import UIKit
#endif
import Foundation

/// Taptic Engine 기반 고급 햅틱 피드백 매니저 (iOS 전용)
@MainActor
public final class HapticManager {
    public static let shared = HapticManager()
    
    private init() {}
    
    /// 가벼운 버튼 탭 피드백
    public func lightImpact() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    /// 묵직한 카드/선택 피드백
    public func mediumImpact() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    /// 목표 달성 성공 피드백
    public func successNotification() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
    
    /// 축하 연타 햅틱 패턴 (팡파레 연출)
    public func celebrationFanfare() {
        #if canImport(UIKit)
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let medium = UIImpactFeedbackGenerator(style: .medium)
        heavy.prepare()
        medium.prepare()
        
        heavy.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            medium.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
        #endif
    }
}

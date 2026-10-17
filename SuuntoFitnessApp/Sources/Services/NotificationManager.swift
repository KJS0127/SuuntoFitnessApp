import Foundation
import UserNotifications

/// 목표 달성 및 리마인더 로컬 푸시 알림 매니저
public final class NotificationManager: @unchecked Sendable {
    public static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - 알림 권한 요청
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("⚠️ 알림 권한 요청 실패: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 일일 목표 100% 달성 축하 푸시 알림 발송
    public func sendGoalAchievedNotification(goalTitle: String, achievementValue: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 일일 운동 목표 달성!"
        content.subtitle = "\(goalTitle) 100% 완료"
        content.body = "멋진 성취입니다! 오늘 \(achievementValue)를 기록하며 목표를 완수하셨습니다. 잠시 앱을 열어 기념 배지를 확인해 보세요."
        content.sound = .default
        
        // 1초 후 즉시 발송
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "goal_achieved_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("⚠️ 푸시 알림 스케줄 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 매일 저녁 목표 달성 리마인더 스케줄 (오후 8시)
    public func scheduleEveningReminder(targetSteps: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🏃 오늘 하루 운동은 어떠셨나요?"
        content.body = "오늘 일일 목표까지 조금 남았습니다! 가벼운 저녁 산책으로 진짜 걸음 \(targetSteps)보를 완성해 보세요."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "evening_daily_goal_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
}

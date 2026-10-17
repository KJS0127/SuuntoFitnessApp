import SwiftUI

/// 러닝 완주 후 느낌(컨디션) 평가 및 최종 저장 모달
public struct WorkoutSummaryModalView: View {
    public let durationSeconds: TimeInterval
    public let distanceMeters: Double
    public let elevationGain: Double
    public let avgHeartRate: Int
    public let cadence: Int
    public let trackPoints: [TrackPoint]
    
    public let onSave: (WorkoutRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFeeling: WorkoutFeeling = .good
    
    public init(
        durationSeconds: TimeInterval,
        distanceMeters: Double,
        elevationGain: Double,
        avgHeartRate: Int,
        cadence: Int,
        trackPoints: [TrackPoint],
        onSave: @escaping (WorkoutRecord) -> Void
    ) {
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.elevationGain = elevationGain
        self.avgHeartRate = avgHeartRate
        self.cadence = cadence
        self.trackPoints = trackPoints
        self.onSave = onSave
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // 헤더
            VStack(spacing: 6) {
                Text("달리기 완주! 🏆")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("오늘의 훌륭한 러닝 세션이 기록되었습니다.")
                    .font(.system(size: 13))
                    .foregroundColor(SuuntoTheme.textSecondary)
            }
            .padding(.top, 24)
            
            // 3단 핵심 요약
            HStack(spacing: 16) {
                SummaryPill(title: "거리", value: String(format: "%.2f km", distanceMeters / 1000.0), color: SuuntoTheme.accentYellow)
                SummaryPill(title: "시간", value: formatDuration(durationSeconds), color: SuuntoTheme.textPrimary)
                SummaryPill(title: "평균 페이스", value: formatPace(calculatePace()), color: SuuntoTheme.accentBlue)
            }
            .padding(.horizontal, 16)
            
            // 운동 후 느낌(Feeling) 선택
            VStack(alignment: .leading, spacing: 12) {
                Text("오늘 운동은 어떠셨나요?")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(SuuntoTheme.textPrimary)
                
                HStack(spacing: 10) {
                    ForEach(WorkoutFeeling.allCases, id: \.self) { feeling in
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            selectedFeeling = feeling
                        }) {
                            VStack(spacing: 6) {
                                Text(feeling.emoji)
                                    .font(.system(size: 28))
                                Text(feeling.rawValue)
                                    .font(.system(size: 11, weight: selectedFeeling == feeling ? .bold : .regular))
                                    .foregroundColor(selectedFeeling == feeling ? SuuntoTheme.accentYellow : SuuntoTheme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedFeeling == feeling ? Color(white: 0.22) : SuuntoTheme.cardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedFeeling == feeling ? SuuntoTheme.accentYellow : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // 저장 버튼
            Button(action: {
                HapticManager.shared.mediumImpact()
                saveWorkout()
            }) {
                Text("러닝 기록 저장하기")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(SuuntoTheme.accentYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(SuuntoTheme.background)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - 저장 및 지표 연산
    private func saveWorkout() {
        let pace = calculatePace()
        // NGP: 고도 상승을 감안해 약간 더 빠른 환산 페이스
        let ngp = max(180, pace - (elevationGain * 0.25))
        
        // 소모 칼로리 추정: 체중 70kg 기준 거리(km) x 70 x 1.036
        let calories = Int((distanceMeters / 1000.0) * 72.5)
        
        // TSS 훈련 부하 추정치
        let tss = (durationSeconds / 3600.0) * (pace > 0 ? (360.0 / pace) * 75.0 : 50.0)
        
        var achievements: [String] = []
        if distanceMeters >= 5000 {
            achievements.append("5km 완주 배지 획득 ⭐")
        }
        achievements.append("오늘의 러닝 완료")
        
        let record = WorkoutRecord(
            id: UUID(),
            activityType: .running,
            startDate: Date().addingTimeInterval(-durationSeconds),
            endDate: Date(),
            deviceName: "Apple Watch & iPhone GPS",
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            averageHeartRateBpm: avgHeartRate,
            maxHeartRateBpm: avgHeartRate + 16,
            averagePaceSecondsPerKm: pace,
            ngpSecondsPerKm: ngp,
            elevationGainMeters: elevationGain,
            tss: tss,
            cadenceSpm: cadence,
            caloriesBurnedKcal: calories,
            feeling: selectedFeeling,
            weather: WorkoutWeather(),
            achievements: achievements,
            trackPoints: trackPoints
        )
        
        onSave(record)
        dismiss()
    }
    
    private func calculatePace() -> Double {
        guard distanceMeters > 50 else { return 360 }
        return (durationSeconds / distanceMeters) * 1000.0
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d'%02d\"", mins, secs)
    }
    
    private func formatPace(_ secPerKm: Double) -> String {
        let mins = Int(secPerKm) / 60
        let secs = Int(secPerKm) % 60
        return String(format: "%02d'%02d /km", mins, secs)
    }
}

private struct SummaryPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(SuuntoTheme.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(SuuntoTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WorkoutSummaryModalView(
        durationSeconds: 1962,
        distanceMeters: 5010,
        elevationGain: 51,
        avgHeartRate: 162,
        cadence: 167,
        trackPoints: []
    ) { _ in }
}

import SwiftUI
import MapKit

/// 실시간 GPS 러닝 트래커 및 순토 스타일 HUD 화면
public struct LiveRunningTrackerView: View {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var motionManager = MotionManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    @Environment(\.dismiss) private var dismiss
    
    // 완주 후 결과 저장 콜백
    public let onFinishWorkout: (WorkoutRecord) -> Void
    
    // 완주 요약 모달 표시 여부
    @State private var showSummaryModal: Bool = false
    @State private var stopButtonProgress: CGFloat = 0.0
    @State private var isHoldingStop: Bool = false
    
    public init(onFinishWorkout: @escaping (WorkoutRecord) -> Void) {
        self.onFinishWorkout = onFinishWorkout
    }
    
    public var body: some View {
        ZStack {
            SuuntoTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 1. 상단 실시간 GPS 지도 (화면 상단 절반)
                ZStack(alignment: .top) {
                    Map(position: .constant(.userLocation(fallback: .automatic))) {
                        UserAnnotation()
                        
                        let coords = locationManager.recordedTrackPoints.map { $0.coordinate }
                        if !coords.isEmpty {
                            MapPolyline(coordinates: coords)
                                .stroke(
                                    LinearGradient(
                                        colors: [SuuntoTheme.accentYellow, SuuntoTheme.accentRed],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                                )
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .frame(height: 320)
                    
                    // 상단 헤더 (취소 버튼 & 자동 일시정지 배너)
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: {
                                HapticManager.shared.lightImpact()
                                _ = locationManager.stopRunTracking()
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.65))
                                    .clipShape(Circle())
                            }
                            Spacer()
                            
                            // GPS 신호 상태
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(locationManager.isTracking ? SuuntoTheme.accentGreen : SuuntoTheme.accentYellow)
                                    .frame(width: 8, height: 8)
                                Text("GPS 연결됨")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        
                        // 자동 일시정지 (Auto-Pause) 알림 배너
                        if locationManager.isAutoPaused {
                            HStack(spacing: 6) {
                                Image(systemName: "pause.circle.fill")
                                Text("신호 대기로 자동 일시정지 중...")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(SuuntoTheme.accentYellow)
                            .clipShape(Capsule())
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                
                // MARK: - 2. 하단 순토 HUD 대형 메트릭 디스플레이
                VStack(spacing: 16) {
                    // 메인 2열 (시간, 거리)
                    HStack(spacing: 16) {
                        HUDMetricBox(
                            title: "지속 시간",
                            value: formatTime(locationManager.durationSeconds),
                            color: SuuntoTheme.textPrimary
                        )
                        HUDMetricBox(
                            title: "거리",
                            value: String(format: "%.2f", locationManager.distanceMeters / 1000.0),
                            unit: "km",
                            color: SuuntoTheme.accentYellow
                        )
                    }
                    
                    // 서브 3열 (현재 페이스, 심박수, 케이던스)
                    HStack(spacing: 12) {
                        HUDSubMetricBox(
                            title: "현재 페이스",
                            value: formatPace(locationManager.currentPaceSecondsPerKm),
                            unit: "/km",
                            color: SuuntoTheme.accentBlue
                        )
                        HUDSubMetricBox(
                            title: "심박수",
                            value: "\(healthKitManager.currentHeartRate ?? 158)",
                            unit: "bpm",
                            color: SuuntoTheme.accentRed
                        )
                        HUDSubMetricBox(
                            title: "케이던스",
                            value: "\(Int(motionManager.currentCadenceSpm > 0 ? motionManager.currentCadenceSpm : 165))",
                            unit: "spm",
                            color: SuuntoTheme.accentGreen
                        )
                    }
                    
                    Spacer()
                    
                    // MARK: - 3. 하단 조작 바 (일시정지 및 완료)
                    HStack(spacing: 24) {
                        // 일시정지 / 재개 버튼
                        Button(action: {
                            HapticManager.shared.mediumImpact()
                            locationManager.togglePause()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(white: 0.18))
                                    .frame(width: 68, height: 68)
                                Image(systemName: locationManager.isTracking ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // 완주 및 종료 버튼 (길게 누르기)
                        ZStack {
                            Circle()
                                .fill(SuuntoTheme.accentRed)
                                .frame(width: 68, height: 68)
                            
                            // 길게 누를 때 채워지는 링 게이지
                            Circle()
                                .trim(from: 0, to: stopButtonProgress)
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 76, height: 76)
                                .rotationEffect(.degrees(-90))
                            
                            Image(systemName: "stop.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isHoldingStop {
                                        isHoldingStop = true
                                        withAnimation(.linear(duration: 1.2)) {
                                            stopButtonProgress = 1.0
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                            if isHoldingStop {
                                                HapticManager.shared.celebrationFanfare()
                                                showSummaryModal = true
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    isHoldingStop = false
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        stopButtonProgress = 0.0
                                    }
                                }
                        )
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .onAppear {
            locationManager.requestLocationAuthorization()
            locationManager.startRunTracking()
        }
        .sheet(isPresented: $showSummaryModal) {
            WorkoutSummaryModalView(
                durationSeconds: locationManager.durationSeconds,
                distanceMeters: locationManager.distanceMeters,
                elevationGain: locationManager.elevationGainMeters,
                avgHeartRate: healthKitManager.currentHeartRate ?? 162,
                cadence: Int(motionManager.currentCadenceSpm > 0 ? motionManager.currentCadenceSpm : 167),
                trackPoints: locationManager.recordedTrackPoints
            ) { completedRecord in
                onFinishWorkout(completedRecord)
                dismiss()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - 포맷터
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatPace(_ secPerKm: Double) -> String {
        guard secPerKm > 0 && secPerKm < 1800 else { return "--'--" }
        let mins = Int(secPerKm) / 60
        let secs = Int(secPerKm) % 60
        return String(format: "%02d'%02d", mins, secs)
    }
}

// MARK: - HUD 지표 박스 서브 컴포넌트
private struct HUDMetricBox: View {
    let title: String
    let value: String
    var unit: String? = nil
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(SuuntoTheme.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                if let unit = unit {
                    Text(unit)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SuuntoTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct HUDSubMetricBox: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(SuuntoTheme.textTertiary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundColor(SuuntoTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(SuuntoTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    LiveRunningTrackerView { _ in }
}

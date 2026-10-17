import SwiftUI
import MapKit

public struct RunDetailView: View {
    public let record: WorkoutRecord
    @Environment(\.dismiss) private var dismiss
    @State private var showAllMetrics: Bool = false
    
    public init(record: WorkoutRecord) {
        self.record = record
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - 1. 상단 GPS 지도 및 경로
                ZStack(alignment: .top) {
                    let coordinates = record.trackPoints.map { $0.coordinate }
                    let region = regionForCoordinates(coordinates)
                    
                    Map(initialPosition: .region(region)) {
                        MapPolyline(coordinates: coordinates)
                            .stroke(
                                LinearGradient(
                                    colors: [SuuntoTheme.accentYellow, SuuntoTheme.accentRed],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                            )
                        
                        if let first = coordinates.first {
                            Annotation("출발", coordinate: first) {
                                Circle().fill(SuuntoTheme.accentGreen).frame(width: 10, height: 10)
                            }
                        }
                        if let last = coordinates.last {
                            Annotation("도착", coordinate: last) {
                                Circle().fill(SuuntoTheme.accentRed).frame(width: 10, height: 10)
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .frame(height: 290)
                    
                    // 네비게이션 버튼 & 날씨 오버레이
                    VStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            Button(action: {}) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        
                        Spacer()
                        
                        // 하단 날씨 & 위치 태그
                        if let weather = record.weather {
                            HStack(spacing: 8) {
                                Text(weather.locationName)
                                    .font(.system(size: 13, weight: .bold))
                                HStack(spacing: 4) {
                                    Image(systemName: weather.symbolName)
                                    Text("\(Int(weather.temperatureCelsius)) °C")
                                }
                                .font(.system(size: 12))
                                HStack(spacing: 3) {
                                    Image(systemName: "wind")
                                    Text("\(Int(weather.windSpeedMps)) m/s")
                                }
                                .font(.system(size: 12))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                }
                
                // MARK: - 2. 러너 정보 및 타이틀
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(SuuntoTheme.accentYellow)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("달리기")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(SuuntoTheme.textPrimary)
                            Text("\(formattedDate(record.startDate))  🔒")
                                .font(.system(size: 13))
                                .foregroundColor(SuuntoTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(white: 0.35))
                    }
                    .padding(.top, 16)
                    
                    // 디바이스 태그
                    HStack(spacing: 8) {
                        DevicePill(icon: "applewatch", title: record.deviceName)
                        DevicePill(icon: "triangle.fill", title: "VO₂max")
                    }
                    
                    // 성과 뱃지 문구
                    if !record.achievements.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(record.achievements, id: \.self) { badge in
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(SuuntoTheme.accentYellow)
                                    Text(badge)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(SuuntoTheme.textPrimary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // MARK: - 3. 2열 핵심 지표 그리드 (스크린샷 1번 완전 복원)
                    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                    LazyVGrid(columns: columns, spacing: 12) {
                        MetricCell(title: "지속 시간", value: formatDuration(record.durationSeconds), hasInfo: true)
                        MetricCell(title: "거리", value: String(format: "%.2f km", record.distanceMeters / 1000))
                        MetricCell(title: "평균 심박수", value: "\(record.averageHeartRateBpm) bpm")
                        MetricCell(title: "평균 페이스", value: formatPace(record.averagePaceSecondsPerKm))
                        MetricCell(title: "NGP® (경사도 보정)", value: formatPace(record.ngpSecondsPerKm), hasInfo: true)
                        MetricCell(title: "상승", value: String(format: "%.0f m", record.elevationGainMeters))
                        MetricCell(title: "TSS (훈련 부하)", value: String(format: "%.0f", record.tss), hasInfo: true)
                        MetricCell(title: "느낌", value: record.feeling.emoji)
                        MetricCell(title: "평균 걸음 케이던스", value: "\(record.cadenceSpm) spm", hasInfo: true)
                        MetricCell(title: "칼로리", value: "\(record.caloriesBurnedKcal) kcal")
                    }
                    .padding(.top, 4)
                    
                    // 하단 '모두 표시' 버튼
                    Button(action: { showAllMetrics.toggle() }) {
                        Text(showAllMetrics ? "간략히 보기" : "모두 표시")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SuuntoTheme.accentBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 40)
            }
        }
        .background(SuuntoTheme.background)
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
    }
    
    // MARK: - 헬퍼 포맷터
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy, HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let ms = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d'%02d.%02d", mins, secs, ms)
    }
    
    private func formatPace(_ secPerKm: Double) -> String {
        let mins = Int(secPerKm) / 60
        let secs = Int(secPerKm) % 60
        return String(format: "%02d'%02d /km", mins, secs)
    }
    
    private func regionForCoordinates(_ coords: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coords.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.5348, longitude: 129.3087),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.015, (lats.max()! - lats.min()!) * 1.6),
            longitudeDelta: max(0.015, (lons.max()! - lons.min()!) * 1.6)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

private struct DevicePill: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(title)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(SuuntoTheme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(white: 0.16))
        .clipShape(Capsule())
    }
}

private struct MetricCell: View {
    let title: String
    let value: String
    var hasInfo: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SuuntoTheme.textSecondary)
                if hasInfo {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundColor(SuuntoTheme.accentBlue)
                }
                Spacer()
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(SuuntoTheme.textPrimary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SuuntoTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SuuntoTheme.cardBorder.opacity(0.35), lineWidth: 1)
        )
    }
}

#Preview {
    RunDetailView(record: MockFitnessData.sampleRunningWorkout)
}

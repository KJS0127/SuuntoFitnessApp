import SwiftUI
import MapKit

public struct MiniMapWidget: View {
    public let workout: WorkoutRecord?
    public let onTap: () -> Void
    
    public init(workout: WorkoutRecord?, onTap: @escaping () -> Void) {
        self.workout = workout
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // 지도 프리뷰
                if let workout = workout, !workout.trackPoints.isEmpty {
                    let coordinates = workout.trackPoints.map { $0.coordinate }
                    let region = regionForCoordinates(coordinates)
                    
                    Map(initialPosition: .region(region)) {
                        MapPolyline(coordinates: coordinates)
                            .stroke(
                                LinearGradient(
                                    colors: [SuuntoTheme.accentYellow, SuuntoTheme.accentRed],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 4
                            )
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .disabled(true) // 미니 위젯이므로 스크롤 비활성화
                } else {
                    Rectangle()
                        .fill(Color(white: 0.15))
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(SuuntoTheme.textTertiary)
                                Text("최근 활동 없음")
                                    .font(.system(size: 11))
                                    .foregroundColor(SuuntoTheme.textTertiary)
                            }
                        )
                }
                
                // 좌측 하단 활동 수 / 거리 뱃지
                HStack(spacing: 5) {
                    Circle()
                        .fill(SuuntoTheme.accentGreen)
                        .frame(width: 6, height: 6)
                    Text(workout != nil ? String(format: "%.2f km", (workout?.distanceMeters ?? 0) / 1000) : "0 활동")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                .padding(10)
                
                // 우측 상단 날짜 태그
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(10)
                    }
                    Spacer()
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: SuuntoTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SuuntoTheme.cardCornerRadius, style: .continuous)
                    .stroke(SuuntoTheme.cardBorder.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.015, (maxLat - minLat) * 1.6),
            longitudeDelta: max(0.015, (maxLon - minLon) * 1.6)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    ZStack {
        SuuntoTheme.background.ignoresSafeArea()
        MiniMapWidget(workout: MockFitnessData.sampleRunningWorkout) {
            print("Tapped mini map")
        }
        .padding()
    }
}

import SwiftUI

// MARK: - 리소스 (바디 배터리) 위젯
public struct BodyResourceWidget: View {
    public let resourcePercentage: Int
    
    public init(resourcePercentage: Int) {
        self.resourcePercentage = resourcePercentage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("리소스")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("지금")
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "cellularbars")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(SuuntoTheme.accentGreen)
                    .clipShape(Circle())
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(resourcePercentage)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(SuuntoTheme.textPrimary)
                Text("%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SuuntoTheme.textSecondary)
            }
            
            // 게이지
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.18))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SuuntoTheme.accentGreen)
                        .frame(width: geo.size.width * CGFloat(resourcePercentage) / 100.0, height: 5)
                }
            }
            .frame(height: 5)
        }
        .suuntoCard()
    }
}

// MARK: - 수면 분석 위젯
public struct SleepWidget: View {
    public let durationSeconds: TimeInterval
    public let sleepDebtHours: Double
    
    public init(durationSeconds: TimeInterval, sleepDebtHours: Double) {
        self.durationSeconds = durationSeconds
        self.sleepDebtHours = sleepDebtHours
    }
    
    public var body: some View {
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("수면")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("어제 밤")
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "moon.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(SuuntoTheme.accentPurple)
                    .clipShape(Circle())
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(hours)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(SuuntoTheme.textPrimary)
                Text("시간")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SuuntoTheme.textSecondary)
                Text("\(minutes)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(SuuntoTheme.textPrimary)
                Text("분")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SuuntoTheme.textSecondary)
            }
            
            Text(String(format: "목표 대비 %+.1f시간", sleepDebtHours))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(sleepDebtHours >= 0 ? SuuntoTheme.accentGreen : SuuntoTheme.accentRed)
        }
        .suuntoCard()
    }
}

// MARK: - 심박수 & HRV 위젯
public struct HeartRateWellnessWidget: View {
    public let heartRate: Int?
    public let hrvSDNN: Double?
    
    public init(heartRate: Int?, hrvSDNN: Double?) {
        self.heartRate = heartRate
        self.hrvSDNN = hrvSDNN
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // 심박수 카드
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("심박수")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.accentRed)
                }
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(heartRate != nil ? "\(heartRate!)" : "--")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("bpm")
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
            }
            .suuntoCard()
            
            // HRV 카드
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("HRV")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Spacer()
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.accentGreen)
                }
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(hrvSDNN != nil ? String(format: "%.0f", hrvSDNN!) : "--")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(SuuntoTheme.textPrimary)
                    Text("ms")
                        .font(.system(size: 12))
                        .foregroundColor(SuuntoTheme.textSecondary)
                }
            }
            .suuntoCard()
        }
    }
}

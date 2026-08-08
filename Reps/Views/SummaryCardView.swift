//
//  SummaryCardView.swift
//  Reps
//
//  The end-of-workout summary card. Shown on the export screens and rendered
//  to an image for Save to Gallery.
//

import SwiftUI

struct SummaryCardView: View {
    let routineName: String
    let date: Date
    let totalVolume: Double
    let totalSets: Int
    let totalReps: Int
    let exerciseCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(routineName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.accent)

            Text(Self.dateText(date))
                .font(.system(size: 14))
                .foregroundStyle(Theme.secondary)
                .padding(.top, 6)

            HStack(alignment: .top, spacing: 0) {
                stat(value: Self.volumeText(totalVolume), caption: "TOTAL VOLUME")
                stat(value: "\(totalSets)", caption: "TOTAL SETS")
                stat(value: "\(totalReps)", caption: "TOTAL REPS")
            }
            .padding(.top, 28)

            HStack {
                Text("Exercises").foregroundStyle(Theme.secondary)
                Spacer()
                Text("\(exerciseCount)").foregroundStyle(Theme.secondary)
            }
            .font(.system(size: 15))
            .padding(.top, 36)

            HStack {
                HStack(spacing: 8) {
                    ForEach(0..<max(exerciseCount, 0), id: \.self) { _ in
                        Circle().fill(Theme.accent).frame(width: 10, height: 10)
                    }
                }
                Spacer()
                Text("\(exerciseCount) lifts").foregroundStyle(Theme.secondary)
            }
            .font(.system(size: 13))
            .padding(.top, 12)

            Spacer(minLength: 0)

            HStack {
                Text("Reps")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text("by Levo Studio")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(28)
        .frame(width: 358, height: 358, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func stat(value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.primary)
            Text(caption)
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Formatting

    static func volumeText(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: volume)) ?? "\(Int(volume))"
        return "\(number) kg"
    }

    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

import SwiftUI

struct SessionSummaryView: View {
    @Bindable var sessionService: SessionService

    private var percentage: Double {
        guard sessionService.itemsReviewed > 0 else { return 0 }
        return Double(sessionService.correctCount) / Double(sessionService.itemsReviewed) * 100
    }

    private var resultColor: Color {
        switch percentage {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var resultIcon: String {
        switch percentage {
        case 80...100: return "star.fill"
        case 60..<80: return "hand.thumbsup.fill"
        case 40..<60: return "book.fill"
        default: return "arrow.clockwise"
        }
    }

    private var resultMessage: String {
        switch percentage {
        case 90...100: return "Perfect! 🎉"
        case 80..<90: return "Excellent! 🌟"
        case 60..<80: return "Great job! 👏"
        case 40..<60: return "Keep it up! 📚"
        default: return "Keep learning! 💪"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Result icon
            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: resultIcon)
                    .font(.system(size: 50))
                    .foregroundStyle(resultColor)
            }

            // Score display
            VStack(spacing: 8) {
                Text("Session Complete!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(resultMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            // Stats grid
            HStack(spacing: 24) {
                summaryStatView(title: "Reviewed", value: "\(sessionService.itemsReviewed)", icon: "eye", color: .blue)
                summaryStatView(title: "Correct", value: "\(sessionService.correctCount)", icon: "checkmark.circle", color: .green)
                summaryStatView(title: "Incorrect", value: "\(sessionService.incorrectCount)", icon: "xmark.circle", color: .red)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            // Percentage bar
            if sessionService.itemsReviewed > 0 {
                VStack(spacing: 4) {
                    ProgressView(value: Double(sessionService.correctCount), total: Double(sessionService.itemsReviewed))
                        .tint(resultColor)
                        .scaleEffect(y: 2)

                    Text("\(Int(percentage))% accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    sessionService.reset()
                } label: {
                    Text("New Session")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private func summaryStatView(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SessionSummaryView(sessionService: SessionService())
}

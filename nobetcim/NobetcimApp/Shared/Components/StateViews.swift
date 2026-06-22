import SwiftUI

struct LoadingStateView: View {
    var message = "Yükleniyor..."

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage = "magnifyingglass"
    var tint: Color = AppTheme.primary

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 220)
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void
    var tint: Color = AppTheme.primary

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(tint)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Tekrar Dene", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(tint)
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 220)
    }
}

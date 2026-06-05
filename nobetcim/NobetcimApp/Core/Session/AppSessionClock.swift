import SwiftUI

/// Oturum boyunca uygulamanın ön planda geçirdiği süreyi ölçer.
@MainActor
final class AppSessionClock {
    static let shared = AppSessionClock()

    private var segmentStart: Date?
    private(set) var accumulatedForeground: TimeInterval = 0

    private init() {}

    var totalForegroundTime: TimeInterval {
        var total = accumulatedForeground
        if let segmentStart {
            total += Date().timeIntervalSince(segmentStart)
        }
        return total
    }

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if segmentStart == nil {
                segmentStart = Date()
            }
        case .inactive, .background:
            closeSegment()
        @unknown default:
            break
        }
    }

    private func closeSegment() {
        guard let segmentStart else { return }
        accumulatedForeground += Date().timeIntervalSince(segmentStart)
        self.segmentStart = nil
    }
}

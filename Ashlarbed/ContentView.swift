import SwiftUI

/// Role: Steeple. Host. Passage first; then steeple-tab chrome. Views never touch the store.
struct ContentView: View {
    @State private var watch: SteepleWatch
    var handlesLaunch: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var ready = false

    init(watch: SteepleWatch = .live(), handlesLaunch: Bool = true) {
        self._watch = State(initialValue: watch)
        self.handlesLaunch = handlesLaunch
        self._ready = State(initialValue: !handlesLaunch)
    }

    var body: some View {
        Group {
            if handlesLaunch && !ready {
                AshlarSwatch.background
                    .ignoresSafeArea()
                    .overlay {
                        Image(AshlarPlate.splash)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
                    .overlay {
                        if watch.isHauling {
                            ProgressView()
                                .tint(AshlarSwatch.accent)
                        }
                    }
            } else if watch.onboardingComplete {
                SteepleChrome(watch: watch)
            } else {
                AshlarPassage(watch: watch)
            }
        }
        .tint(AshlarSwatch.accent)
        .preferredColorScheme(.light)
        .background(AshlarSwatch.background.ignoresSafeArea())
        .task {
            guard handlesLaunch else {
                ready = true
                watch.applyReview()
                return
            }
            await watch.appear()
            ready = true
            await Task.yield()
            watch.applyReview()
        }
        .onChange(of: watch.onboardingComplete) { _, complete in
            if complete, ready {
                watch.applyReview()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard handlesLaunch else { return }
            if phase == .inactive || phase == .background {
                Task { await watch.flush() }
            }
            if phase == .active {
                watch.markDay()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            watch.markDay()
        }
    }
}

#Preview {
    ContentView(watch: .previewPopulated(), handlesLaunch: false)
}

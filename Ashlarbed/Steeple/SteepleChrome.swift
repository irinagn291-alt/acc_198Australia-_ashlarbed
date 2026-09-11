import SwiftUI

/// Role: Steeple. Steeple-tab chrome. Tower holds the steeple and fused set log; Analytics and Settings are siblings.
struct SteepleChrome: View {
    @Bindable var watch: SteepleWatch
    @State private var tab: SteepleTab

    init(watch: SteepleWatch) {
        self.watch = watch
        watch.applyReview()
        _tab = State(initialValue: watch.tab)
    }

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: $tab) {
                    Tab("Tower", systemImage: "building.columns", value: SteepleTab.tower) {
                        NavigationStack {
                            TowerPane(watch: watch)
                        }
                    }
                    Tab("Analytics", systemImage: "chart.bar", value: SteepleTab.analytics) {
                        NavigationStack {
                            AnalyticsPane(watch: watch)
                        }
                    }
                    Tab("Settings", systemImage: "gearshape", value: SteepleTab.settings) {
                        NavigationStack {
                            AshlarSettings(watch: watch)
                        }
                    }
                }
                .tabViewStyle(.tabBarOnly)
            } else {
                TabView(selection: $tab) {
                    NavigationStack {
                        TowerPane(watch: watch)
                    }
                    .tabItem {
                        Label("Tower", systemImage: "building.columns")
                    }
                    .tag(SteepleTab.tower)

                    NavigationStack {
                        AnalyticsPane(watch: watch)
                    }
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar")
                    }
                    .tag(SteepleTab.analytics)

                    NavigationStack {
                        AshlarSettings(watch: watch)
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(SteepleTab.settings)
                }
            }
        }
        .id(tab)
        .toolbarBackground(AshlarSwatch.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(AshlarSwatch.accent)
        .onAppear {
            watch.applyReview()
            tab = watch.tab
        }
        .onChange(of: tab) { _, new in
            watch.tab = new
        }
        .onChange(of: watch.tab) { _, new in
            tab = new
        }
    }
}

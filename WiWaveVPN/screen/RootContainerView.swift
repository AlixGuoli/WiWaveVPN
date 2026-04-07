import SwiftUI

/// 根容器：冷启动页 →（首装）引导 → 主页；老用户冷启动页 → 主页。
struct RootContainerView: View {
    @EnvironmentObject private var launchGate: AppLaunchGate
    @State private var stage: LaunchStage = .coldSplash

    private enum LaunchStage: Equatable {
        case coldSplash
        case onboarding
        case main
    }

    var body: some View {
        Group {
            switch stage {
            case .coldSplash:
                LaunchSplashView {
                    finishColdSplash()
                }
            case .onboarding:
                OnboardingFlowView {
                    launchGate.markOnboardingFinished()
                    stage = .main
                }
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.22), value: stage)
        .onChange(of: launchGate.hasCompletedOnboarding) { completed in
            if !completed, stage == .main {
                stage = .onboarding
            }
        }
    }

    private func finishColdSplash() {
        if launchGate.hasCompletedOnboarding {
            stage = .main
        } else {
            stage = .onboarding
        }
    }
}

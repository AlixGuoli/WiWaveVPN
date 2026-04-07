//
//  ContentView.swift
//  WiWaveVPN
//
//  Created by ersao on 2026/4/1.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var coil: WiSessionCoordinator
    @State private var path: [WiRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            homeLayer
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: WiRoute.self) { step in
                    switch step {
                    case .progress:
                        WiProgressScreen()
                    case .verdict(let v):
                        WiOutcomeScreen(verdict: v)
                    }
                }
        }
        .onChange(of: coil.showProgressPage) { show in
            if show {
                if path.last != .progress {
                    path.append(.progress)
                }
            } else if path.last == .progress {
                path.removeLast()
            }
        }
        .onChange(of: coil.verdict) { newVal in
            guard let v = newVal else { return }
            if path.last == .progress {
                path.removeLast()
            }
            if case .verdict = path.last {
                path.removeLast()
            }
            path.append(.verdict(v))
        }
        .alert("断开连接？", isPresented: $coil.showUnplugConfirm) {
            Button("断开", role: .destructive) { coil.confirmUnplug() }
            Button("取消", role: .cancel) { coil.cancelUnplug() }
        } message: {
            Text("将停止当前隧道。")
        }
    }

    private var homeLayer: some View {
        VStack(spacing: 20) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text("WiWave VPN")
                .font(.title2.weight(.bold))
            Text(statusLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { coil.tapHero() }) {
                Text(heroTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(coil.phase == .busy && !coil.showUnplugConfirm)
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var heroTitle: String {
        switch coil.phase {
        case .offline, .error: return "连接"
        case .online: return "断开"
        case .busy: return "处理中…"
        }
    }

    private var statusLine: String {
        switch coil.phase {
        case .offline: return "未连接"
        case .busy: return "正在建立或关闭隧道…"
        case .online: return "已连接"
        case .error: return "上次未能建立隧道，可重试。"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WiSessionCoordinator())
}

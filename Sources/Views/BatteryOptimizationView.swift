//
//  BatteryOptimizationView.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import SwiftUI

// MARK: - BatteryOptimizationView

struct BatteryOptimizationView: View {
    @StateObject private var batteryOptimizer = BatteryOptimizer()
    @State private var showingReport = false

    var body: some View {
        NavigationView {
            List {
                // 現在の状態セクション
                Section("現在の状態") {
                    currentStatusSection
                }

                // 最適化設定セクション
                Section("最適化設定") {
                    optimizationSettingsSection
                }

                // 統計情報セクション
                Section("統計情報") {
                    statisticsSection
                }

                // アクションセクション
                Section("アクション") {
                    actionSection
                }
            }
            .navigationTitle("バッテリー最適化")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingReport) {
                BatteryOptimizationReportView(
                    report: batteryOptimizer.getBatteryOptimizationReport()
                )
            }
        }
        .onAppear {
            batteryOptimizer.startOptimization()
        }
        .onDisappear {
            batteryOptimizer.stopOptimization()
        }
    }

    // MARK: - Current Status Section

    private var currentStatusSection: some View {
        Group {
            HStack {
                Image(systemName: "battery.100")
                    .foregroundColor(batteryColor)
                Text("バッテリー残量")
                Spacer()
                Text("\(Int(batteryOptimizer.batteryLevel * 100))%")
                    .fontWeight(.semibold)
            }

            HStack {
                Image(systemName: thermalStateIcon)
                    .foregroundColor(thermalStateColor)
                Text("デバイス温度")
                Spacer()
                Text(thermalStateText)
                    .fontWeight(.semibold)
            }

            HStack {
                Image(systemName: "bolt.circle")
                    .foregroundColor(batteryOptimizer.isLowPowerModeEnabled ? .orange : .gray)
                Text("低電力モード")
                Spacer()
                Text(batteryOptimizer.isLowPowerModeEnabled ? "有効" : "無効")
                    .fontWeight(.semibold)
            }

            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.blue)
                Text("最適化レベル")
                Spacer()
                Text(batteryOptimizer.batteryOptimizationLevel.displayName)
                    .fontWeight(.semibold)
                    .foregroundColor(optimizationLevelColor)
            }
        }
    }

    // MARK: - Optimization Settings Section

    private var optimizationSettingsSection: some View {
        Group {
            Toggle("熱制御の有効化", isOn: .constant(batteryOptimizer.thermalThrottlingEnabled))
                .disabled(true) // 読み取り専用として表示

            Toggle("自動最適化", isOn: .constant(batteryOptimizer.autoOptimizationEnabled))
                .disabled(true) // 読み取り専用として表示

            HStack {
                Text("CPU使用率目標")
                Spacer()
                Text("\(Int(batteryOptimizer.cpuUsageTarget * 100))%")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        Group {
            HStack {
                Text("熱最適化回数")
                Spacer()
                Text("\(batteryOptimizer.optimizationStats.thermalOptimizations)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("バッテリー最適化回数")
                Spacer()
                Text("\(batteryOptimizer.optimizationStats.batteryOptimizations)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("CPU最適化回数")
                Spacer()
                Text("\(batteryOptimizer.optimizationStats.cpuOptimizations)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("バックグラウンド最適化回数")
                Spacer()
                Text("\(batteryOptimizer.optimizationStats.backgroundOptimizations)")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        Group {
            Button("詳細レポートを表示") {
                showingReport = true
            }
            .foregroundColor(.blue)

            Button("統計をリセット") {
                batteryOptimizer.resetStatistics()
            }
            .foregroundColor(.orange)
        }
    }

    // MARK: - Computed Properties

    private var batteryColor: Color {
        if batteryOptimizer.batteryLevel > 0.5 {
            return .green
        } else if batteryOptimizer.batteryLevel > 0.2 {
            return .orange
        } else {
            return .red
        }
    }

    private var thermalStateIcon: String {
        switch batteryOptimizer.thermalState {
        case .nominal:
            return "thermometer"
        case .fair:
            return "thermometer.medium"
        case .serious:
            return "thermometer.high"
        case .critical:
            return "exclamationmark.thermometer"
        @unknown default:
            return "thermometer"
        }
    }

    private var thermalStateColor: Color {
        switch batteryOptimizer.thermalState {
        case .nominal:
            return .green
        case .fair:
            return .yellow
        case .serious:
            return .orange
        case .critical:
            return .red
        @unknown default:
            return .gray
        }
    }

    private var thermalStateText: String {
        switch batteryOptimizer.thermalState {
        case .nominal:
            return "正常"
        case .fair:
            return "やや高温"
        case .serious:
            return "高温"
        case .critical:
            return "危険"
        @unknown default:
            return "不明"
        }
    }

    private var optimizationLevelColor: Color {
        switch batteryOptimizer.batteryOptimizationLevel {
        case .balanced:
            return .blue
        case .powerSaving:
            return .green
        case .aggressive:
            return .orange
        case .maximum:
            return .red
        }
    }
}

// MARK: - BatteryOptimizationReportView

struct BatteryOptimizationReportView: View {
    let report: BatteryOptimizationReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                // サマリーセクション
                Section("サマリー") {
                    summarySection
                }

                // 統計セクション
                Section("詳細統計") {
                    detailedStatisticsSection
                }

                // 推奨事項セクション
                if !report.recommendations.isEmpty {
                    Section("推奨事項") {
                        recommendationsSection
                    }
                }
            }
            .navigationTitle("最適化レポート")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        Group {
            HStack {
                Text("現在の最適化レベル")
                Spacer()
                Text(report.currentLevel.displayName)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("バッテリー残量")
                Spacer()
                Text(report.formattedBatteryLevel)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("デバイス温度状態")
                Spacer()
                Text(report.thermalStateDisplayName)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("低電力モード")
                Spacer()
                Text(report.isLowPowerModeEnabled ? "有効" : "無効")
                    .fontWeight(.semibold)
            }

            if let duration = report.stats.optimizationDuration {
                HStack {
                    Text("最適化実行時間")
                    Spacer()
                    Text(formatDuration(duration))
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Detailed Statistics Section

    private var detailedStatisticsSection: some View {
        Group {
            HStack {
                Text("熱状態変更回数")
                Spacer()
                Text("\(report.stats.thermalStateChanges)")
            }

            HStack {
                Text("熱最適化実行回数")
                Spacer()
                Text("\(report.stats.thermalOptimizations)")
            }

            HStack {
                Text("バッテリー最適化実行回数")
                Spacer()
                Text("\(report.stats.batteryOptimizations)")
            }

            HStack {
                Text("低電力モード有効化回数")
                Spacer()
                Text("\(report.stats.lowPowerModeActivations)")
            }

            HStack {
                Text("CPU最適化実行回数")
                Spacer()
                Text("\(report.stats.cpuOptimizations)")
            }

            HStack {
                Text("バックグラウンド最適化回数")
                Spacer()
                Text("\(report.stats.backgroundOptimizations)")
            }

            // 最適化レベル別統計
            Group {
                HStack {
                    Text("バランス最適化回数")
                    Spacer()
                    Text("\(report.stats.balancedOptimizations)")
                }

                HStack {
                    Text("省電力最適化回数")
                    Spacer()
                    Text("\(report.stats.powerSavingOptimizations)")
                }

                HStack {
                    Text("積極的最適化回数")
                    Spacer()
                    Text("\(report.stats.aggressiveOptimizations)")
                }

                HStack {
                    Text("最大限最適化回数")
                    Spacer()
                    Text("\(report.stats.maximumOptimizations)")
                }
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        ForEach(report.recommendations, id: \.self) { recommendation in
            HStack(alignment: .top) {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                    .padding(.top, 2)
                Text(recommendation)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
        }
    }

    // MARK: - Helper Methods

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "不明"
    }
}

// MARK: - Preview

#Preview {
    BatteryOptimizationView()
}

#Preview("Report") {
    BatteryOptimizationReportView(
        report: BatteryOptimizationReport(
            currentLevel: .powerSaving,
            batteryLevel: 0.45,
            thermalState: .fair,
            isLowPowerModeEnabled: false,
            stats: BatteryOptimizationStats(),
            recommendations: [
                "バッテリー残量が少なくなっています。充電を検討してください。",
                "デバイスが熱くなっています。しばらく使用を控えることを推奨します。"
            ]
        )
    )
}

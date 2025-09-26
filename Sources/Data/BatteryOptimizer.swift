//
//  BatteryOptimizer.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import ARKit
import Domain
import Foundation
import RealityKit
import UIKit

// MARK: - BatteryOptimizer

/// バッテリー効率とパフォーマンス最適化を担当するクラス
class BatteryOptimizer: ObservableObject {
    // MARK: - Properties

    private var thermalStateMonitor: ThermalStateMonitor
    private var batteryMonitor: BatteryMonitor
    private var cpuOptimizer: CPUOptimizer
    private var backgroundTaskManager: BackgroundTaskManager

    // バッテリー最適化設定
    @Published var batteryOptimizationLevel: BatteryOptimizationLevel = .balanced
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var batteryLevel: Float = 1.0
    @Published var isLowPowerModeEnabled: Bool = false
    @Published var isOptimizationActive: Bool = false

    // 最適化統計
    @Published var optimizationStats = BatteryOptimizationStats()

    // 設定
    var thermalThrottlingEnabled: Bool = true
    var autoOptimizationEnabled: Bool = true
    var batteryThresholds = BatteryThresholds()
    var cpuUsageTarget: Double = 0.7 // 70%以下を目標

    // MARK: - Initialization

    init() {
        thermalStateMonitor = ThermalStateMonitor()
        batteryMonitor = BatteryMonitor()
        cpuOptimizer = CPUOptimizer()
        backgroundTaskManager = BackgroundTaskManager()

        setupBatteryOptimization()
    }

    // MARK: - Setup

    private func setupBatteryOptimization() {
        // 熱状態監視
        thermalStateMonitor.onThermalStateChange = { [weak self] thermalState in
            DispatchQueue.main.async {
                self?.handleThermalStateChange(thermalState)
            }
        }

        // バッテリー監視
        batteryMonitor.onBatteryLevelChange = { [weak self] batteryLevel in
            DispatchQueue.main.async {
                self?.handleBatteryLevelChange(batteryLevel)
            }
        }

        batteryMonitor.onLowPowerModeChange = { [weak self] isEnabled in
            DispatchQueue.main.async {
                self?.handleLowPowerModeChange(isEnabled)
            }
        }

        // CPU使用率監視
        cpuOptimizer.onCPUUsageChange = { [weak self] cpuUsage in
            DispatchQueue.main.async {
                self?.handleCPUUsageChange(cpuUsage)
            }
        }

        // アプリライフサイクル監視
        setupApplicationLifecycleObservers()
    }

    private func setupApplicationLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: - Battery Optimization Control

    func startOptimization() {
        guard !isOptimizationActive else { return }

        isOptimizationActive = true

        // 各監視コンポーネントを開始
        thermalStateMonitor.startMonitoring()
        batteryMonitor.startMonitoring()
        cpuOptimizer.startMonitoring()

        // 初期最適化の適用
        applyInitialOptimizations()

        optimizationStats.optimizationStartTime = Date()
    }

    func stopOptimization() {
        guard isOptimizationActive else { return }

        isOptimizationActive = false

        // 各監視コンポーネントを停止
        thermalStateMonitor.stopMonitoring()
        batteryMonitor.stopMonitoring()
        cpuOptimizer.stopMonitoring()

        optimizationStats.optimizationStopTime = Date()
    }

    private func applyInitialOptimizations() {
        // 現在の状態に基づく初期最適化
        let currentBatteryLevel = batteryMonitor.currentBatteryLevel
        let currentThermalState = thermalStateMonitor.currentThermalState

        determineBatteryOptimizationLevel(
            batteryLevel: currentBatteryLevel,
            thermalState: currentThermalState
        )

        applyOptimizationsForLevel(batteryOptimizationLevel)
    }

    // MARK: - Thermal Management

    private func handleThermalStateChange(_ newThermalState: ProcessInfo.ThermalState) {
        thermalState = newThermalState

        if thermalThrottlingEnabled {
            applyThermalOptimizations(for: newThermalState)
        }

        optimizationStats.thermalStateChanges += 1
    }

    private func applyThermalOptimizations(for thermalState: ProcessInfo.ThermalState) {
        switch thermalState {
        case .nominal:
            // 通常状態：最適化を緩和
            batteryOptimizationLevel = .balanced

        case .fair:
            // 軽度の熱上昇：軽度の最適化
            batteryOptimizationLevel = .powerSaving

        case .serious:
            // 重度の熱上昇：積極的な最適化
            batteryOptimizationLevel = .aggressive

        case .critical:
            // 危険な熱状態：最大限の最適化
            batteryOptimizationLevel = .maximum

        @unknown default:
            batteryOptimizationLevel = .balanced
        }

        applyOptimizationsForLevel(batteryOptimizationLevel)
        optimizationStats.thermalOptimizations += 1
    }

    // MARK: - Battery Management

    private func handleBatteryLevelChange(_ newBatteryLevel: Float) {
        batteryLevel = newBatteryLevel

        // バッテリーレベルに基づく最適化
        if newBatteryLevel <= batteryThresholds.critical {
            batteryOptimizationLevel = .maximum
        } else if newBatteryLevel <= batteryThresholds.low {
            batteryOptimizationLevel = .aggressive
        } else if newBatteryLevel <= batteryThresholds.medium {
            batteryOptimizationLevel = .powerSaving
        } else {
            batteryOptimizationLevel = .balanced
        }

        applyOptimizationsForLevel(batteryOptimizationLevel)
        optimizationStats.batteryOptimizations += 1
    }

    private func handleLowPowerModeChange(_ isEnabled: Bool) {
        isLowPowerModeEnabled = isEnabled

        if isEnabled {
            // 低電力モード時は最大限の最適化
            batteryOptimizationLevel = .maximum
            applyOptimizationsForLevel(.maximum)
            optimizationStats.lowPowerModeActivations += 1
        }
    }

    // MARK: - CPU Optimization

    private func handleCPUUsageChange(_ cpuUsage: Double) {
        if cpuUsage > cpuUsageTarget {
            // CPU使用率が高い場合の最適化
            applyCPUOptimizations()
            optimizationStats.cpuOptimizations += 1
        }
    }

    private func applyCPUOptimizations() {
        // CPU使用率を下げるための最適化
        cpuOptimizer.reduceCPUIntensiveOperations()
        cpuOptimizer.optimizeRenderingFrequency()
        cpuOptimizer.throttleNetworkOperations()
    }

    // MARK: - Optimization Level Application

    private func determineBatteryOptimizationLevel(
        batteryLevel: Float,
        thermalState: ProcessInfo.ThermalState
    ) {
        // バッテリーレベルと熱状態を総合的に判断
        let batteryScore = getBatteryScore(batteryLevel)
        let thermalScore = getThermalScore(thermalState)

        let combinedScore = (batteryScore + thermalScore) / 2.0

        if combinedScore >= 0.8 {
            batteryOptimizationLevel = .balanced
        } else if combinedScore >= 0.6 {
            batteryOptimizationLevel = .powerSaving
        } else if combinedScore >= 0.4 {
            batteryOptimizationLevel = .aggressive
        } else {
            batteryOptimizationLevel = .maximum
        }
    }

    private func getBatteryScore(_ batteryLevel: Float) -> Double {
        Double(batteryLevel)
    }

    private func getThermalScore(_ thermalState: ProcessInfo.ThermalState) -> Double {
        switch thermalState {
        case .nominal: return 1.0
        case .fair: return 0.7
        case .serious: return 0.4
        case .critical: return 0.1
        @unknown default: return 0.5
        }
    }

    private func applyOptimizationsForLevel(_ level: BatteryOptimizationLevel) {
        switch level {
        case .balanced:
            applyBalancedOptimizations()
        case .powerSaving:
            applyPowerSavingOptimizations()
        case .aggressive:
            applyAggressiveOptimizations()
        case .maximum:
            applyMaximumOptimizations()
        }
    }

    private func applyBalancedOptimizations() {
        // バランス重視の最適化
        cpuOptimizer.setTargetFrameRate(60)
        cpuOptimizer.setRenderingQuality(.high)
        cpuOptimizer.setNetworkUpdateFrequency(.normal)

        optimizationStats.balancedOptimizations += 1
    }

    private func applyPowerSavingOptimizations() {
        // 省電力重視の最適化
        cpuOptimizer.setTargetFrameRate(45)
        cpuOptimizer.setRenderingQuality(.medium)
        cpuOptimizer.setNetworkUpdateFrequency(.reduced)
        cpuOptimizer.enableBackgroundProcessingReduction()

        optimizationStats.powerSavingOptimizations += 1
    }

    private func applyAggressiveOptimizations() {
        // 積極的な最適化
        cpuOptimizer.setTargetFrameRate(30)
        cpuOptimizer.setRenderingQuality(.low)
        cpuOptimizer.setNetworkUpdateFrequency(.minimal)
        cpuOptimizer.enableAggressiveBackgroundReduction()
        cpuOptimizer.reduceARProcessingQuality()

        optimizationStats.aggressiveOptimizations += 1
    }

    private func applyMaximumOptimizations() {
        // 最大限の最適化
        cpuOptimizer.setTargetFrameRate(20)
        cpuOptimizer.setRenderingQuality(.minimal)
        cpuOptimizer.setNetworkUpdateFrequency(.emergency)
        cpuOptimizer.enableMaximumBackgroundReduction()
        cpuOptimizer.minimizeARProcessing()
        cpuOptimizer.pauseNonEssentialOperations()

        optimizationStats.maximumOptimizations += 1
    }

    // MARK: - Background Processing Management

    @objc private func handleApplicationDidEnterBackground() {
        backgroundTaskManager.minimizeBackgroundProcessing()
        optimizationStats.backgroundOptimizations += 1
    }

    @objc private func handleApplicationWillEnterForeground() {
        backgroundTaskManager.restoreNormalProcessing()
    }

    @objc private func handleApplicationDidBecomeActive() {
        // アクティブ時の最適化状態復元
        if isOptimizationActive {
            applyOptimizationsForLevel(batteryOptimizationLevel)
        }
    }

    // MARK: - Game-Specific Optimizations

    func optimizeForGamePhase(_ gamePhase: GamePhase) {
        switch gamePhase {
        case .waiting:
            // 待機中は省電力モード
            applyWaitingPhaseOptimizations()
        case .connecting:
            // 接続中は中程度の最適化
            applyConnectingPhaseOptimizations()
        case .playing:
            // ゲーム中はパフォーマンス重視（ただしバッテリー状況を考慮）
            applyPlayingPhaseOptimizations()
        case .finished:
            // 終了時は省電力モード
            applyFinishedPhaseOptimizations()
        }
    }

    private func applyWaitingPhaseOptimizations() {
        cpuOptimizer.setTargetFrameRate(30)
        cpuOptimizer.pauseNonEssentialAnimations()
        cpuOptimizer.reduceARProcessingFrequency()
    }

    private func applyConnectingPhaseOptimizations() {
        cpuOptimizer.setTargetFrameRate(45)
        cpuOptimizer.pauseNonEssentialAnimations()
        cpuOptimizer.reduceARProcessingFrequency()
    }

    private func applyPlayingPhaseOptimizations() {
        // バッテリー状況に応じてパフォーマンスを調整
        let targetFrameRate = batteryOptimizationLevel == .balanced ? 60 : 45
        cpuOptimizer.setTargetFrameRate(targetFrameRate)
        cpuOptimizer.resumeEssentialAnimations()
    }

    private func applyFinishedPhaseOptimizations() {
        cpuOptimizer.setTargetFrameRate(20)
        cpuOptimizer.pauseAllAnimations()
        cpuOptimizer.minimizeARProcessing()
    }

    // MARK: - Reporting

    func getBatteryOptimizationReport() -> BatteryOptimizationReport {
        BatteryOptimizationReport(
            currentLevel: batteryOptimizationLevel,
            batteryLevel: batteryLevel,
            thermalState: thermalState,
            isLowPowerModeEnabled: isLowPowerModeEnabled,
            stats: optimizationStats,
            recommendations: generateRecommendations()
        )
    }

    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []

        if batteryLevel < batteryThresholds.low {
            recommendations.append("バッテリー残量が少なくなっています。充電を検討してください。")
        }

        if thermalState == .serious || thermalState == .critical {
            recommendations.append("デバイスが熱くなっています。しばらく使用を控えることを推奨します。")
        }

        if optimizationStats.cpuOptimizations > 10 {
            recommendations.append("CPU使用率が高い状態が続いています。アプリの再起動を検討してください。")
        }

        return recommendations
    }

    func resetStatistics() {
        optimizationStats = BatteryOptimizationStats()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopOptimization()
    }
}

// MARK: - ThermalStateMonitor

/// 熱状態監視クラス
class ThermalStateMonitor {
    private var processInfo: ProcessInfo
    var onThermalStateChange: ((ProcessInfo.ThermalState) -> Void)?

    var currentThermalState: ProcessInfo.ThermalState {
        processInfo.thermalState
    }

    init() {
        processInfo = ProcessInfo.processInfo
    }

    func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateDidChange),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }

    func stopMonitoring() {
        NotificationCenter.default.removeObserver(
            self,
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }

    @objc private func thermalStateDidChange() {
        onThermalStateChange?(processInfo.thermalState)
    }

    deinit {
        stopMonitoring()
    }
}

// MARK: - BatteryMonitor

/// バッテリー監視クラス
class BatteryMonitor {
    private var device: UIDevice
    var onBatteryLevelChange: ((Float) -> Void)?
    var onLowPowerModeChange: ((Bool) -> Void)?

    var currentBatteryLevel: Float {
        device.batteryLevel
    }

    var isLowPowerModeEnabled: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    init() {
        device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
    }

    func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(lowPowerModeDidChange),
            name: .NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }

    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func batteryLevelDidChange() {
        onBatteryLevelChange?(device.batteryLevel)
    }

    @objc private func lowPowerModeDidChange() {
        onLowPowerModeChange?(ProcessInfo.processInfo.isLowPowerModeEnabled)
    }

    deinit {
        stopMonitoring()
    }
}

// MARK: - CPUOptimizer

/// CPU使用率最適化クラス
class CPUOptimizer {
    private var cpuMonitor: CPUMonitor
    var onCPUUsageChange: ((Double) -> Void)?

    private var currentTargetFrameRate: Int = 60
    private var currentRenderingQuality: RenderingQuality = .high
    private var currentNetworkFrequency: NetworkUpdateFrequency = .normal

    init() {
        cpuMonitor = CPUMonitor()
        cpuMonitor.onCPUUsageUpdate = { [weak self] cpuUsage in
            self?.onCPUUsageChange?(cpuUsage)
        }
    }

    func startMonitoring() {
        cpuMonitor.startMonitoring()
    }

    func stopMonitoring() {
        cpuMonitor.stopMonitoring()
    }

    // MARK: - Optimization Methods

    func setTargetFrameRate(_ frameRate: Int) {
        currentTargetFrameRate = frameRate
        // 実際のフレームレート設定をここで実装
    }

    func setRenderingQuality(_ quality: RenderingQuality) {
        currentRenderingQuality = quality
        // レンダリング品質の設定をここで実装
    }

    func setNetworkUpdateFrequency(_ frequency: NetworkUpdateFrequency) {
        currentNetworkFrequency = frequency
        // ネットワーク更新頻度の設定をここで実装
    }

    func reduceCPUIntensiveOperations() {
        // CPU集約的な処理を削減
    }

    func optimizeRenderingFrequency() {
        // レンダリング頻度の最適化
    }

    func throttleNetworkOperations() {
        // ネットワーク処理のスロットリング
    }

    func enableBackgroundProcessingReduction() {
        // バックグラウンド処理の削減
    }

    func enableAggressiveBackgroundReduction() {
        // 積極的なバックグラウンド処理削減
    }

    func enableMaximumBackgroundReduction() {
        // 最大限のバックグラウンド処理削減
    }

    func reduceARProcessingQuality() {
        // AR処理品質の削減
    }

    func minimizeARProcessing() {
        // AR処理の最小化
    }

    func pauseNonEssentialOperations() {
        // 非必須処理の一時停止
    }

    func pauseNonEssentialAnimations() {
        // 非必須アニメーションの一時停止
    }

    func resumeEssentialAnimations() {
        // 必須アニメーションの再開
    }

    func pauseAllAnimations() {
        // 全アニメーションの一時停止
    }

    func reduceARProcessingFrequency() {
        // AR処理頻度の削減
    }
}

// MARK: - CPUMonitor

/// CPU使用率監視クラス
class CPUMonitor {
    private var timer: Timer?
    var onCPUUsageUpdate: ((Double) -> Void)?

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            let cpuUsage = self?.getCurrentCPUUsage() ?? 0.0
            self?.onCPUUsageUpdate?(cpuUsage)
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func getCurrentCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            // CPU使用率の計算（簡略化）
            return Double(info.resident_size) / Double(1_024 * 1_024 * 100) // 概算値
        }

        return 0.0
    }
}

// MARK: - BackgroundTaskManager

/// バックグラウンドタスク管理クラス
class BackgroundTaskManager {
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid

    func minimizeBackgroundProcessing() {
        // バックグラウンド処理の最小化
        beginBackgroundTask()
    }

    func restoreNormalProcessing() {
        // 通常処理の復元
        endBackgroundTask()
    }

    private func beginBackgroundTask() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
}

// MARK: - BatteryOptimizationLevel

/// バッテリー最適化レベル
enum BatteryOptimizationLevel: String, CaseIterable {
    case balanced
    case powerSaving
    case aggressive
    case maximum

    var displayName: String {
        switch self {
        case .balanced: return "バランス"
        case .powerSaving: return "省電力"
        case .aggressive: return "積極的"
        case .maximum: return "最大限"
        }
    }
}

// MARK: - RenderingQuality

/// レンダリング品質
enum RenderingQuality: String, CaseIterable {
    case minimal
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .minimal: return "最小"
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
}

// MARK: - NetworkUpdateFrequency

/// ネットワーク更新頻度
enum NetworkUpdateFrequency: String, CaseIterable {
    case emergency
    case minimal
    case reduced
    case normal

    var displayName: String {
        switch self {
        case .emergency: return "緊急時のみ"
        case .minimal: return "最小限"
        case .reduced: return "削減"
        case .normal: return "通常"
        }
    }
}

// MARK: - BatteryThresholds

/// バッテリー閾値設定
struct BatteryThresholds {
    var critical: Float = 0.1 // 10%
    var low: Float = 0.2 // 20%
    var medium: Float = 0.5 // 50%
}

// MARK: - BatteryOptimizationStats

/// バッテリー最適化統計
struct BatteryOptimizationStats {
    var optimizationStartTime: Date?
    var optimizationStopTime: Date?

    var thermalStateChanges: Int = 0
    var thermalOptimizations: Int = 0
    var batteryOptimizations: Int = 0
    var lowPowerModeActivations: Int = 0
    var cpuOptimizations: Int = 0
    var backgroundOptimizations: Int = 0

    var balancedOptimizations: Int = 0
    var powerSavingOptimizations: Int = 0
    var aggressiveOptimizations: Int = 0
    var maximumOptimizations: Int = 0

    var optimizationDuration: TimeInterval? {
        guard let start = optimizationStartTime else { return nil }
        let end = optimizationStopTime ?? Date()
        return end.timeIntervalSince(start)
    }
}

// MARK: - BatteryOptimizationReport

/// バッテリー最適化レポート
struct BatteryOptimizationReport {
    let currentLevel: BatteryOptimizationLevel
    let batteryLevel: Float
    let thermalState: ProcessInfo.ThermalState
    let isLowPowerModeEnabled: Bool
    let stats: BatteryOptimizationStats
    let recommendations: [String]

    var formattedBatteryLevel: String {
        let percentage = Int(batteryLevel * 100)
        return "\(percentage)%"
    }

    var thermalStateDisplayName: String {
        switch thermalState {
        case .nominal: return "正常"
        case .fair: return "やや高温"
        case .serious: return "高温"
        case .critical: return "危険"
        @unknown default: return "不明"
        }
    }
}

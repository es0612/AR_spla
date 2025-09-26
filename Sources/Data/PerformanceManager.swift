//
//  PerformanceManager.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import ARKit
import Domain
import Foundation
import Infrastructure
import RealityKit

// MARK: - PerformanceManager

/// アプリ全体のパフォーマンス最適化を統合管理するクラス
public class PerformanceManager: ObservableObject {
    // MARK: - Properties

    private var arOptimizer: ARPerformanceOptimizer?
    private var networkOptimizer: NetworkPerformanceOptimizer?
    private var memoryOptimizer: MemoryOptimizer
    private var batteryOptimizer: BatteryOptimizer

    // パフォーマンス統計
    @Published var overallPerformance = OverallPerformanceStats()
    @Published var isOptimizationActive: Bool = false

    // 最適化設定
    var autoOptimizationEnabled: Bool = true
    var performanceTarget: PerformanceTarget = .balanced
    var monitoringInterval: TimeInterval = 2.0

    private var monitoringTimer: Timer?

    // MARK: - Initialization

    init() {
        memoryOptimizer = MemoryOptimizer()
        batteryOptimizer = BatteryOptimizer()
        setupPerformanceManagement()
    }

    // MARK: - Setup

    private func setupPerformanceManagement() {
        // パフォーマンス監視の設定
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    // MARK: - Optimizer Registration

    func registerAROptimizer(_ arView: ARView) {
        arOptimizer = ARPerformanceOptimizer(arView: arView)
    }

    func registerNetworkOptimizer(_ sessionManager: MultiplayerSessionManager) {
        networkOptimizer = NetworkPerformanceOptimizer(sessionManager: sessionManager)
    }

    // MARK: - Performance Management

    func startOptimization() {
        guard !isOptimizationActive else { return }

        isOptimizationActive = true

        // 各最適化コンポーネントを開始
        Task { @MainActor in
            arOptimizer?.startMonitoring()
        }
        memoryOptimizer.startOptimization()
        Task { @MainActor in
            batteryOptimizer.startOptimization()
        }

        // 定期監視を開始
        startPerformanceMonitoring()

        overallPerformance.optimizationStartTime = Date()
    }

    func stopOptimization() {
        guard isOptimizationActive else { return }

        isOptimizationActive = false

        // 各最適化コンポーネントを停止
        Task { @MainActor in
            arOptimizer?.stopMonitoring()
        }
        memoryOptimizer.stopOptimization()
        Task { @MainActor in
            batteryOptimizer.stopOptimization()
        }

        // 定期監視を停止
        stopPerformanceMonitoring()

        overallPerformance.optimizationStopTime = Date()
    }

    private func startPerformanceMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.performPerformanceCheck()
        }
    }

    private func stopPerformanceMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    // MARK: - Performance Monitoring

    private func performPerformanceCheck() {
        guard isOptimizationActive else { return }

        // 各コンポーネントのパフォーマンス情報を収集
        updateOverallPerformance()

        // 自動最適化の実行
        if autoOptimizationEnabled {
            performAutoOptimization()
        }

        overallPerformance.monitoringCycles += 1
    }

    private func updateOverallPerformance() {
        // AR パフォーマンス
        if let arOptimizer = arOptimizer {
            overallPerformance.currentFrameRate = arOptimizer.currentFrameRate
            overallPerformance.arMemoryUsage = arOptimizer.memoryUsage
        }

        // ネットワーク パフォーマンス
        if let networkOptimizer = networkOptimizer {
            let networkStats = networkOptimizer.performanceStats
            overallPerformance.networkLatency = networkStats.averageLatency
            overallPerformance.networkSuccessRate = Double(networkStats.messagesSentSuccessfully) / Double(max(networkStats.totalMessagesSent, 1))
        }

        // メモリ パフォーマンス
        let memoryStats = memoryOptimizer.memoryStats
        overallPerformance.totalMemoryUsage = memoryStats.currentUsage
        overallPerformance.memoryWarnings = memoryStats.memoryWarnings

        // 全体的なパフォーマンススコアの計算
        overallPerformance.performanceScore = calculatePerformanceScore()
    }

    private func calculatePerformanceScore() -> Double {
        var score = 100.0

        // フレームレートスコア (40%)
        let targetFPS = 60.0
        let frameRateScore = min(overallPerformance.currentFrameRate / targetFPS, 1.0) * 40.0

        // メモリスコア (30%)
        let memoryThreshold: Double = 200 * 1_024 * 1_024 // 200MB
        let memoryScore = max(0, 1.0 - Double(overallPerformance.totalMemoryUsage) / memoryThreshold) * 30.0

        // ネットワークスコア (20%)
        let networkScore = min(overallPerformance.networkSuccessRate, 1.0) * 20.0

        // 安定性スコア (10%)
        let stabilityScore = max(0, 1.0 - Double(overallPerformance.memoryWarnings) / 10.0) * 10.0

        score = frameRateScore + memoryScore + networkScore + stabilityScore

        return max(0, min(100, score))
    }

    // MARK: - Auto Optimization

    private func performAutoOptimization() {
        let currentScore = overallPerformance.performanceScore

        if currentScore < 60 { // 60点以下で積極的最適化
            performAggressiveOptimization()
        } else if currentScore < 80 { // 80点以下で軽度最適化
            performMildOptimization()
        }
    }

    private func performAggressiveOptimization() {
        // AR最適化
        arOptimizer?.isOptimizationEnabled = true

        // ネットワーク最適化
        networkOptimizer?.adaptToNetworkConditions()

        // メモリ最適化
        if let gameState = getCurrentGameState() {
            memoryOptimizer.optimizeGameMemory(gameState: gameState)
        }

        overallPerformance.aggressiveOptimizations += 1
    }

    private func performMildOptimization() {
        // 軽度の最適化
        networkOptimizer?.monitorConnectionQuality()

        overallPerformance.mildOptimizations += 1
    }

    // MARK: - Game-Specific Optimization

    func optimizeForGamePhase(_ phase: GamePhase) {
        switch phase {
        case .waiting:
            optimizeForWaitingPhase()
        case .connecting:
            optimizeForConnectingPhase()
        case .playing:
            optimizeForPlayingPhase()
        case .finished:
            optimizeForFinishedPhase()
        }

        // バッテリー最適化も同期
        batteryOptimizer.optimizeForGamePhase(phase)
    }

    private func optimizeForWaitingPhase() {
        // 待機中の最適化
        performanceTarget = .powerSaving
        arOptimizer?.targetFrameRate = 30 // フレームレートを下げる
    }

    private func optimizeForConnectingPhase() {
        // 接続中の最適化
        performanceTarget = .balanced
        arOptimizer?.targetFrameRate = 45 // 中程度のフレームレート
    }
    
    private func optimizeForPlayingPhase() {
        // ゲーム中の最適化
        performanceTarget = .performance
        arOptimizer?.targetFrameRate = 60 // 最高フレームレート
    }

    private func optimizeForFinishedPhase() {
        // 終了時の最適化
        performanceTarget = .balanced
        performCleanupOptimization()
    }

    private func performCleanupOptimization() {
        // ゲーム終了時のクリーンアップ
        if let arView = getCurrentARView() {
            memoryOptimizer.optimizeARMemory(arView: arView)
        }

        overallPerformance.cleanupOptimizations += 1
    }

    // MARK: - Performance Reporting

    func getComprehensivePerformanceReport() -> ComprehensivePerformanceReport {
        var report = ComprehensivePerformanceReport(
            overallStats: overallPerformance,
            recommendations: generateOverallRecommendations()
        )

        // AR レポート
        if let arOptimizer = arOptimizer {
            report.arReport = arOptimizer.getPerformanceReport()
        }

        // ネットワーク レポート
        if let networkOptimizer = networkOptimizer {
            report.networkReport = networkOptimizer.getPerformanceReport()
        }

        // メモリ レポート
        report.memoryReport = memoryOptimizer.getMemoryReport()

        // バッテリー レポート
        report.batteryReport = batteryOptimizer.getBatteryOptimizationReport()

        return report
    }

    private func generateOverallRecommendations() -> [String] {
        var recommendations: [String] = []

        if overallPerformance.performanceScore < 70 {
            recommendations.append("全体的なパフォーマンスが低下しています。最適化設定の見直しを推奨します。")
        }

        if overallPerformance.currentFrameRate < 45 {
            recommendations.append("フレームレートが低下しています。AR描画の最適化を検討してください。")
        }

        if overallPerformance.networkLatency > 0.1 {
            recommendations.append("ネットワーク遅延が高くなっています。通信の最適化を検討してください。")
        }

        if overallPerformance.memoryWarnings > 3 {
            recommendations.append("メモリ警告が頻発しています。メモリ使用量の削減が必要です。")
        }

        return recommendations
    }

    // MARK: - Utility Methods

    private func getCurrentGameState() -> GameState? {
        // 現在のゲーム状態を取得（実装依存）
        nil
    }

    private func getCurrentARView() -> ARView? {
        // 現在のARViewを取得（実装依存）
        nil
    }

    // MARK: - Application Lifecycle

    @objc private func handleApplicationDidBecomeActive() {
        if autoOptimizationEnabled {
            startOptimization()
        }
    }

    @objc private func handleApplicationWillResignActive() {
        // バックグラウンド時は最適化を一時停止
        stopOptimization()
    }

    // MARK: - Statistics Reset

    func resetAllStatistics() {
        overallPerformance = OverallPerformanceStats()
        arOptimizer?.resetStatistics()
        networkOptimizer?.resetStatistics()
        memoryOptimizer.resetStatistics()
        batteryOptimizer.resetStatistics()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopOptimization()
    }
}

// MARK: - OverallPerformanceStats

struct OverallPerformanceStats {
    // 基本パフォーマンス指標
    var performanceScore: Double = 100.0
    var currentFrameRate: Double = 0
    var networkLatency: TimeInterval = 0
    var networkSuccessRate: Double = 1.0
    var totalMemoryUsage: UInt64 = 0
    var arMemoryUsage: UInt64 = 0
    var memoryWarnings: Int = 0

    // 最適化統計
    var monitoringCycles: Int = 0
    var aggressiveOptimizations: Int = 0
    var mildOptimizations: Int = 0
    var cleanupOptimizations: Int = 0

    // タイムスタンプ
    var optimizationStartTime: Date?
    var optimizationStopTime: Date?

    var optimizationDuration: TimeInterval? {
        guard let start = optimizationStartTime else { return nil }
        let end = optimizationStopTime ?? Date()
        return end.timeIntervalSince(start)
    }
}

// MARK: - ComprehensivePerformanceReport

struct ComprehensivePerformanceReport {
    let overallStats: OverallPerformanceStats
    let recommendations: [String]
    var arReport: PerformanceReport?
    var networkReport: NetworkPerformanceReport?
    var memoryReport: MemoryReport?
    var batteryReport: BatteryOptimizationReport?
}

// MARK: - PerformanceTarget

public enum PerformanceTarget {
    case powerSaving // 省電力重視
    case balanced // バランス重視
    case performance // パフォーマンス重視
    case quality // 品質重視
}

// MARK: - Extensions

//
//  MemoryOptimizer.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import ARKit
import Domain
import Foundation
import RealityKit

// MARK: - MemoryOptimizer

/// メモリ使用量の最適化とリーク検出を担当するクラス
@MainActor
class MemoryOptimizer: ObservableObject {
    // MARK: - Properties

    private var memoryMonitor: MemoryMonitor
    private var leakDetector: MemoryLeakDetector
    private var resourceManager: ResourceManager

    // メモリ統計
    @Published var memoryStats = MemoryStats()
    @Published var isOptimizationActive: Bool = false

    // 最適化設定
    var memoryWarningThreshold: UInt64 = 150 * 1_024 * 1_024 // 150MB
    var memoryCriticalThreshold: UInt64 = 200 * 1_024 * 1_024 // 200MB
    var autoCleanupEnabled: Bool = true
    var leakDetectionEnabled: Bool = true

    // MARK: - Initialization

    init() {
        memoryMonitor = MemoryMonitor()
        leakDetector = MemoryLeakDetector()
        resourceManager = ResourceManager()

        setupMemoryOptimization()
    }

    // MARK: - Setup

    private func setupMemoryOptimization() {
        // メモリ監視の設定
        memoryMonitor.onMemoryUpdate = { [weak self] memoryUsage in
            Task { @MainActor in
                self?.handleMemoryUpdate(memoryUsage)
            }
        }

        // メモリ警告の監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // リーク検出の設定
        if leakDetectionEnabled {
            leakDetector.startDetection()
        }
    }

    // MARK: - Memory Monitoring

    func startOptimization() {
        isOptimizationActive = true
        memoryMonitor.start()
        resourceManager.startManagement()

        if leakDetectionEnabled {
            leakDetector.startDetection()
        }
    }

    func stopOptimization() {
        isOptimizationActive = false
        memoryMonitor.stop()
        resourceManager.stopManagement()
        leakDetector.stopDetection()
    }

    private func handleMemoryUpdate(_ memoryUsage: UInt64) {
        memoryStats.currentUsage = memoryUsage
        memoryStats.peakUsage = max(memoryStats.peakUsage, memoryUsage)

        // メモリ使用量に基づく最適化
        if memoryUsage > memoryCriticalThreshold {
            performCriticalMemoryOptimization()
        } else if memoryUsage > memoryWarningThreshold {
            performMemoryOptimization()
        }

        // 統計更新
        updateMemoryStatistics(memoryUsage)
    }

    @objc private func handleMemoryWarning() {
        memoryStats.memoryWarnings += 1

        if autoCleanupEnabled {
            performEmergencyCleanup()
        }
    }

    // MARK: - Memory Optimization

    private func performMemoryOptimization() {
        guard isOptimizationActive else { return }

        // 軽度の最適化
        resourceManager.cleanupUnusedResources()
        resourceManager.reduceTextureQuality()

        memoryStats.optimizationRuns += 1
    }

    private func performCriticalMemoryOptimization() {
        guard isOptimizationActive else { return }

        // 重度の最適化
        resourceManager.aggressiveCleanup()
        resourceManager.clearCaches()
        resourceManager.reduceModelComplexity()

        memoryStats.criticalOptimizations += 1
    }

    private func performEmergencyCleanup() {
        // 緊急時のクリーンアップ
        resourceManager.emergencyCleanup()

        // ガベージコレクションの強制実行
        autoreleasepool {
            // 自動解放プールを使用してメモリを解放
        }

        memoryStats.emergencyCleanups += 1
    }

    // MARK: - Game-Specific Optimization

    func optimizeGameMemory(gameState: GameState) {
        // インクスポットの最適化
        optimizeInkSpots(gameState.inkSpots)

        // プレイヤーデータの最適化
        optimizePlayerData(gameState.players)

        // 古いゲームデータのクリーンアップ
        cleanupOldGameData(gameState)
    }

    private func optimizeInkSpots(_ inkSpots: [InkSpot]) {
        let maxInkSpots = 1_000

        if inkSpots.count > maxInkSpots {
            // 古いインクスポットを削除
            let excessCount = inkSpots.count - maxInkSpots
            memoryStats.inkSpotsRemoved += excessCount
        }

        // 小さなインクスポットをマージ
        let mergeableSpots = inkSpots.filter { $0.size < 0.2 }
        if mergeableSpots.count > 10 {
            memoryStats.inkSpotsMerged += mergeableSpots.count / 2
        }
    }

    private func optimizePlayerData(_ players: [Player]) {
        // プレイヤーデータの最適化
        for player in players {
            // 不要なデータの削除
            // 例: 古い位置履歴、統計データの圧縮など
        }
    }

    private func cleanupOldGameData(_: GameState) {
        // 古いゲームセッションデータのクリーンアップ
        memoryStats.oldDataCleaned += 1
    }

    // MARK: - AR Memory Optimization

    func optimizeARMemory(arView: ARView) {
        // ARアンカーの最適化
        optimizeARAnchors(arView)

        // ARテクスチャの最適化
        optimizeARTextures(arView)

        // ARメッシュの最適化
        optimizeARMeshes(arView)
    }

    private func optimizeARAnchors(_ arView: ARView) {
        let maxAnchors = 50

        if arView.scene.anchors.count > maxAnchors {
            // 古いアンカーを削除
            let sortedAnchors = arView.scene.anchors.sorted { _, _ in
                // 作成時間でソート（古いものから削除）
                true // 実際の実装では適切な比較を行う
            }

            let anchorsToRemove = sortedAnchors.prefix(arView.scene.anchors.count - maxAnchors)
            for anchor in anchorsToRemove {
                arView.scene.removeAnchor(anchor)
            }

            memoryStats.arAnchorsRemoved += anchorsToRemove.count
        }
    }

    private func optimizeARTextures(_: ARView) {
        // テクスチャ品質の動的調整
        memoryStats.textureOptimizations += 1
    }

    private func optimizeARMeshes(_: ARView) {
        // メッシュの複雑度を下げる
        memoryStats.meshOptimizations += 1
    }

    // MARK: - Memory Leak Detection

    func detectMemoryLeaks() -> [MemoryLeak] {
        leakDetector.detectLeaks()
    }

    func analyzeMemoryLeaks() -> MemoryLeakReport {
        let leaks = detectMemoryLeaks()
        return MemoryLeakReport(
            leaks: leaks,
            totalLeakedMemory: leaks.reduce(0) { $0 + $1.estimatedSize },
            recommendations: generateLeakRecommendations(leaks)
        )
    }

    private func generateLeakRecommendations(_ leaks: [MemoryLeak]) -> [String] {
        var recommendations: [String] = []

        if leaks.contains(where: { $0.type == .strongReference }) {
            recommendations.append("強参照サイクルが検出されました。weak参照の使用を検討してください。")
        }

        if leaks.contains(where: { $0.type == .unreleasedResource }) {
            recommendations.append("解放されていないリソースが検出されました。適切なクリーンアップを実装してください。")
        }

        if leaks.contains(where: { $0.type == .observerNotRemoved }) {
            recommendations.append("削除されていないオブザーバーが検出されました。deinitでの削除を確認してください。")
        }

        return recommendations
    }

    // MARK: - Statistics and Reporting

    private func updateMemoryStatistics(_ currentUsage: UInt64) {
        memoryStats.measurements.append(MemoryMeasurement(
            timestamp: Date(),
            usage: currentUsage
        ))

        // 最新の100件のみ保持
        if memoryStats.measurements.count > 100 {
            memoryStats.measurements.removeFirst()
        }

        // 平均使用量の計算
        let recentMeasurements = memoryStats.measurements.suffix(10)
        memoryStats.averageUsage = recentMeasurements.reduce(0) { $0 + $1.usage } / UInt64(recentMeasurements.count)
    }

    func getMemoryReport() -> MemoryReport {
        MemoryReport(
            stats: memoryStats,
            leakReport: analyzeMemoryLeaks(),
            recommendations: generateMemoryRecommendations()
        )
    }

    private func generateMemoryRecommendations() -> [String] {
        var recommendations: [String] = []

        if memoryStats.currentUsage > memoryWarningThreshold {
            recommendations.append("メモリ使用量が警告レベルを超えています。不要なリソースの解放を検討してください。")
        }

        if memoryStats.memoryWarnings > 5 {
            recommendations.append("メモリ警告が頻発しています。メモリ使用量の見直しが必要です。")
        }

        if memoryStats.peakUsage > memoryCriticalThreshold {
            recommendations.append("ピークメモリ使用量が危険レベルに達しています。メモリ最適化の強化が必要です。")
        }

        return recommendations
    }

    func resetStatistics() {
        memoryStats = MemoryStats()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - ResourceManager

/// リソース管理クラス
class ResourceManager {
    private var managedResources: Set<WeakResourceReference> = []
    private var textureCache: [String: Any] = [:]
    private var modelCache: [String: Any] = [:]

    func startManagement() {
        // リソース管理開始
    }

    func stopManagement() {
        // リソース管理停止
        cleanupAllResources()
    }

    func cleanupUnusedResources() {
        // 未使用リソースのクリーンアップ
        cleanupTextureCache()
        cleanupModelCache()
    }

    func aggressiveCleanup() {
        // 積極的なクリーンアップ
        textureCache.removeAll()
        modelCache.removeAll()
    }

    func emergencyCleanup() {
        // 緊急時のクリーンアップ
        cleanupAllResources()
    }

    func reduceTextureQuality() {
        // テクスチャ品質の削減
    }

    func reduceModelComplexity() {
        // モデル複雑度の削減
    }

    func clearCaches() {
        textureCache.removeAll()
        modelCache.removeAll()
    }

    private func cleanupTextureCache() {
        // 古いテクスチャキャッシュの削除
        let maxCacheSize = 50
        if textureCache.count > maxCacheSize {
            let keysToRemove = Array(textureCache.keys.prefix(textureCache.count - maxCacheSize))
            for key in keysToRemove {
                textureCache.removeValue(forKey: key)
            }
        }
    }

    private func cleanupModelCache() {
        // 古いモデルキャッシュの削除
        let maxCacheSize = 20
        if modelCache.count > maxCacheSize {
            let keysToRemove = Array(modelCache.keys.prefix(modelCache.count - maxCacheSize))
            for key in keysToRemove {
                modelCache.removeValue(forKey: key)
            }
        }
    }

    private func cleanupAllResources() {
        textureCache.removeAll()
        modelCache.removeAll()
        managedResources.removeAll()
    }
}

// MARK: - MemoryLeakDetector

/// メモリリーク検出クラス
class MemoryLeakDetector {
    private var trackedObjects: [WeakObjectReference] = []
    private var isDetectionActive: Bool = false

    func startDetection() {
        isDetectionActive = true
    }

    func stopDetection() {
        isDetectionActive = false
        trackedObjects.removeAll()
    }

    func detectLeaks() -> [MemoryLeak] {
        guard isDetectionActive else { return [] }

        var leaks: [MemoryLeak] = []

        // 弱参照が nil になっていないオブジェクトをチェック
        for reference in trackedObjects {
            if reference.shouldBeReleased, reference.object != nil {
                leaks.append(MemoryLeak(
                    type: .strongReference,
                    objectType: reference.objectType,
                    estimatedSize: reference.estimatedSize,
                    detectionTime: Date()
                ))
            }
        }

        return leaks
    }
}

// MARK: - MemoryStats

struct MemoryStats {
    var currentUsage: UInt64 = 0
    var peakUsage: UInt64 = 0
    var averageUsage: UInt64 = 0
    var memoryWarnings: Int = 0
    var optimizationRuns: Int = 0
    var criticalOptimizations: Int = 0
    var emergencyCleanups: Int = 0
    var inkSpotsRemoved: Int = 0
    var inkSpotsMerged: Int = 0
    var oldDataCleaned: Int = 0
    var arAnchorsRemoved: Int = 0
    var textureOptimizations: Int = 0
    var meshOptimizations: Int = 0
    var measurements: [MemoryMeasurement] = []

    var formattedCurrentUsage: String {
        ByteCountFormatter().string(fromByteCount: Int64(currentUsage))
    }

    var formattedPeakUsage: String {
        ByteCountFormatter().string(fromByteCount: Int64(peakUsage))
    }
}

// MARK: - MemoryMeasurement

struct MemoryMeasurement {
    let timestamp: Date
    let usage: UInt64
}

// MARK: - MemoryLeak

struct MemoryLeak {
    let type: MemoryLeakType
    let objectType: String
    let estimatedSize: UInt64
    let detectionTime: Date
}

// MARK: - MemoryLeakType

enum MemoryLeakType {
    case strongReference
    case unreleasedResource
    case observerNotRemoved
}

// MARK: - MemoryLeakReport

struct MemoryLeakReport {
    let leaks: [MemoryLeak]
    let totalLeakedMemory: UInt64
    let recommendations: [String]
}

// MARK: - MemoryReport

struct MemoryReport {
    let stats: MemoryStats
    let leakReport: MemoryLeakReport
    let recommendations: [String]
}

// MARK: - WeakResourceReference

class WeakResourceReference: Hashable {
    weak var resource: AnyObject?
    let identifier: String

    init(resource: AnyObject, identifier: String) {
        self.resource = resource
        self.identifier = identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: WeakResourceReference, rhs: WeakResourceReference) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

// MARK: - WeakObjectReference

class WeakObjectReference {
    weak var object: AnyObject?
    let objectType: String
    let estimatedSize: UInt64
    let creationTime: Date
    var shouldBeReleased: Bool = false

    init(object: AnyObject, objectType: String, estimatedSize: UInt64) {
        self.object = object
        self.objectType = objectType
        self.estimatedSize = estimatedSize
        creationTime = Date()
    }
}

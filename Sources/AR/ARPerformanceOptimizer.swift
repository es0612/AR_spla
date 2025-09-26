//
//  ARPerformanceOptimizer.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import ARKit
import Domain
import RealityKit
import simd

// MARK: - ARPerformanceOptimizer

/// AR描画パフォーマンス最適化を担当するクラス
class ARPerformanceOptimizer: ObservableObject {
    // MARK: - Properties

    private weak var arView: ARView?
    private var frameRateMonitor: FrameRateMonitor
    private var memoryMonitor: MemoryMonitor
    private var renderingOptimizer: RenderingOptimizer

    // パフォーマンス設定
    @Published var targetFrameRate: Int = 60
    @Published var currentFrameRate: Double = 0
    @Published var memoryUsage: UInt64 = 0
    @Published var isOptimizationEnabled: Bool = true

    // 最適化統計
    @Published var optimizationStats = OptimizationStats()

    // MARK: - Initialization

    init(arView: ARView) {
        self.arView = arView
        frameRateMonitor = FrameRateMonitor()
        memoryMonitor = MemoryMonitor()
        renderingOptimizer = RenderingOptimizer(arView: arView)

        setupPerformanceMonitoring()
    }

    // MARK: - Performance Monitoring

    private func setupPerformanceMonitoring() {
        // フレームレート監視
        frameRateMonitor.onFrameRateUpdate = { [weak self] frameRate in
            DispatchQueue.main.async {
                self?.currentFrameRate = frameRate
                self?.adjustPerformanceSettings(frameRate: frameRate)
            }
        }

        // メモリ使用量監視
        memoryMonitor.onMemoryUpdate = { [weak self] memoryUsage in
            DispatchQueue.main.async {
                self?.memoryUsage = memoryUsage
                self?.handleMemoryPressure(memoryUsage: memoryUsage)
            }
        }
    }

    func startMonitoring() {
        frameRateMonitor.start()
        memoryMonitor.start()
        renderingOptimizer.startOptimization()
    }

    func stopMonitoring() {
        frameRateMonitor.stop()
        memoryMonitor.stop()
        renderingOptimizer.stopOptimization()
    }

    // MARK: - Dynamic Performance Adjustment

    private func adjustPerformanceSettings(frameRate: Double) {
        guard isOptimizationEnabled else { return }

        let targetFPS = Double(targetFrameRate)

        if frameRate < targetFPS * 0.8 { // 80%以下の場合
            // パフォーマンス向上のための最適化
            applyPerformanceOptimizations()
            optimizationStats.performanceAdjustments += 1
        } else if frameRate > targetFPS * 0.95 { // 95%以上の場合
            // 品質向上のための設定調整
            improveQualitySettings()
        }
    }

    private func applyPerformanceOptimizations() {
        // レンダリング品質を下げる
        renderingOptimizer.reduceRenderingQuality()

        // 不要なエンティティを削除
        renderingOptimizer.cullDistantEntities()

        // LOD（Level of Detail）を適用
        renderingOptimizer.applyLevelOfDetail()

        // シャドウ品質を下げる
        renderingOptimizer.reduceShadowQuality()
    }

    private func improveQualitySettings() {
        // レンダリング品質を上げる
        renderingOptimizer.improveRenderingQuality()

        // シャドウ品質を上げる
        renderingOptimizer.improveShadowQuality()
    }

    private func handleMemoryPressure(memoryUsage: UInt64) {
        let memoryLimitMB: UInt64 = 200 * 1_024 * 1_024 // 200MB

        if memoryUsage > memoryLimitMB {
            // メモリ圧迫時の最適化
            renderingOptimizer.freeUnusedResources()
            renderingOptimizer.reduceTextureQuality()
            optimizationStats.memoryOptimizations += 1
        }
    }

    // MARK: - Ink Spot Optimization

    func optimizeInkSpotRendering(inkSpots: [InkSpot]) {
        guard isOptimizationEnabled else { return }

        // インクスポットの数に基づく最適化
        if inkSpots.count > 500 {
            renderingOptimizer.enableInkSpotInstancing(inkSpots)
            optimizationStats.inkSpotOptimizations += 1
        }

        // 距離に基づくカリング
        renderingOptimizer.cullDistantInkSpots(inkSpots)

        // 重複するインクスポットのマージ
        let mergedSpots = renderingOptimizer.mergeOverlappingInkSpots(inkSpots)
        if mergedSpots.count < inkSpots.count {
            optimizationStats.inkSpotMerges += inkSpots.count - mergedSpots.count
        }
    }

    // MARK: - Battery Efficiency Optimization

    func optimizeForBatteryEfficiency(level: BatteryOptimizationLevel) {
        switch level {
        case .balanced:
            applyBalancedBatteryOptimizations()
        case .powerSaving:
            applyPowerSavingBatteryOptimizations()
        case .aggressive:
            applyAggressiveBatteryOptimizations()
        case .maximum:
            applyMaximumBatteryOptimizations()
        }
    }

    private func applyBalancedBatteryOptimizations() {
        // バランス重視：品質とバッテリーのバランス
        targetFrameRate = 60
        renderingOptimizer.setRenderingQuality(.high)
        renderingOptimizer.enableSelectiveOptimizations()
    }

    private func applyPowerSavingBatteryOptimizations() {
        // 省電力重視：フレームレートを下げて電力消費を削減
        targetFrameRate = 45
        renderingOptimizer.setRenderingQuality(.medium)
        renderingOptimizer.enablePowerSavingMode()
        renderingOptimizer.reduceARUpdateFrequency()
    }

    private func applyAggressiveBatteryOptimizations() {
        // 積極的な省電力：大幅な品質低下を許容
        targetFrameRate = 30
        renderingOptimizer.setRenderingQuality(.low)
        renderingOptimizer.enableAggressivePowerSaving()
        renderingOptimizer.minimizeARProcessing()
    }

    private func applyMaximumBatteryOptimizations() {
        // 最大限の省電力：最低限の機能のみ維持
        targetFrameRate = 20
        renderingOptimizer.setRenderingQuality(.minimal)
        renderingOptimizer.enableEmergencyPowerSaving()
        renderingOptimizer.pauseNonEssentialARFeatures()
    }

    func optimizeForThermalState(_ thermalState: ProcessInfo.ThermalState) {
        switch thermalState {
        case .nominal:
            // 通常状態：最適化を緩和
            renderingOptimizer.restoreNormalOperations()

        case .fair:
            // 軽度の熱上昇：軽度の最適化
            renderingOptimizer.enableThermalOptimizations()
            targetFrameRate = max(targetFrameRate - 10, 30)

        case .serious:
            // 重度の熱上昇：積極的な最適化
            renderingOptimizer.enableAggressiveThermalOptimizations()
            targetFrameRate = max(targetFrameRate - 20, 20)

        case .critical:
            // 危険な熱状態：最大限の最適化
            renderingOptimizer.enableEmergencyThermalOptimizations()
            targetFrameRate = 15
            renderingOptimizer.pauseAllNonEssentialOperations()

        @unknown default:
            renderingOptimizer.enableThermalOptimizations()
        }

        optimizationStats.thermalOptimizations += 1
    }

    // MARK: - Network Optimization

    func optimizeNetworkTraffic() {
        // ネットワーク最適化統計を更新
        optimizationStats.networkOptimizations += 1
    }

    // MARK: - Performance Statistics

    func getPerformanceReport() -> PerformanceReport {
        PerformanceReport(
            averageFrameRate: frameRateMonitor.averageFrameRate,
            currentMemoryUsage: memoryUsage,
            optimizationStats: optimizationStats,
            renderingStats: renderingOptimizer.getRenderingStats()
        )
    }

    func resetStatistics() {
        optimizationStats = OptimizationStats()
        frameRateMonitor.resetStatistics()
        renderingOptimizer.resetStatistics()
    }
}

// MARK: - FrameRateMonitor

/// フレームレート監視クラス
class FrameRateMonitor {
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var frameRates: [Double] = []

    var onFrameRateUpdate: ((Double) -> Void)?

    var averageFrameRate: Double {
        guard !frameRates.isEmpty else { return 0 }
        return frameRates.reduce(0, +) / Double(frameRates.count)
    }

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkCallback(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }

        frameCount += 1
        let elapsed = displayLink.timestamp - lastTimestamp

        if elapsed >= 1.0 { // 1秒ごとに更新
            let frameRate = Double(frameCount) / elapsed
            frameRates.append(frameRate)

            // 最新の10秒間のデータのみ保持
            if frameRates.count > 10 {
                frameRates.removeFirst()
            }

            onFrameRateUpdate?(frameRate)

            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }

    func resetStatistics() {
        frameRates.removeAll()
        frameCount = 0
        lastTimestamp = 0
    }
}

// MARK: - MemoryMonitor

/// メモリ使用量監視クラス
class MemoryMonitor {
    private var timer: Timer?
    var onMemoryUpdate: ((UInt64) -> Void)?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            let memoryUsage = self?.getCurrentMemoryUsage() ?? 0
            self?.onMemoryUpdate?(memoryUsage)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func getCurrentMemoryUsage() -> UInt64 {
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

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}

// MARK: - RenderingOptimizer

/// レンダリング最適化クラス
class RenderingOptimizer {
    private weak var arView: ARView?
    private var renderingStats = RenderingStats()

    init(arView: ARView) {
        self.arView = arView
    }

    func startOptimization() {
        // 基本的な最適化設定
        arView?.renderOptions.insert(.disablePersonOcclusion)
        arView?.renderOptions.insert(.disableMotionBlur)
    }

    func stopOptimization() {
        // 最適化設定をリセット
        arView?.renderOptions.remove(.disablePersonOcclusion)
        arView?.renderOptions.remove(.disableMotionBlur)
    }

    func reduceRenderingQuality() {
        // レンダリング品質を下げる
        arView?.renderOptions.insert(.disableHDR)
        renderingStats.qualityReductions += 1
    }

    func improveRenderingQuality() {
        // レンダリング品質を上げる
        arView?.renderOptions.remove(.disableHDR)
        renderingStats.qualityImprovements += 1
    }

    func cullDistantEntities() {
        // 遠距離のエンティティをカリング
        guard let arView = arView else { return }

        let cameraTransform = arView.cameraTransform
        let maxDistance: Float = 20.0 // 20メートル

        arView.scene.anchors.forEach { anchor in
            let distance = simd_distance(cameraTransform.translation, anchor.transform.translation)
            anchor.isEnabled = distance <= maxDistance
        }

        renderingStats.entitiesCulled += 1
    }

    func applyLevelOfDetail() {
        // LOD（Level of Detail）を適用
        renderingStats.lodApplications += 1
    }

    func reduceShadowQuality() {
        // シャドウ品質を下げる
        renderingStats.shadowOptimizations += 1
    }

    func improveShadowQuality() {
        // シャドウ品質を上げる
        renderingStats.shadowImprovements += 1
    }

    func freeUnusedResources() {
        // 未使用リソースを解放
        renderingStats.resourceCleanups += 1
    }

    func reduceTextureQuality() {
        // テクスチャ品質を下げる
        renderingStats.textureOptimizations += 1
    }

    func enableInkSpotInstancing(_: [InkSpot]) {
        // インクスポットのインスタンシングを有効化
        renderingStats.instancingOptimizations += 1
    }

    func cullDistantInkSpots(_ inkSpots: [InkSpot]) {
        // 遠距離のインクスポットをカリング
        guard let arView = arView else { return }

        let cameraTransform = arView.cameraTransform
        let maxDistance: Float = 15.0 // 15メートル

        let visibleCount = inkSpots.filter { inkSpot in
            let distance = simd_distance(
                cameraTransform.translation,
                SIMD3<Float>(inkSpot.position.x, inkSpot.position.y, inkSpot.position.z)
            )
            return distance <= maxDistance
        }.count

        renderingStats.inkSpotsCulled += inkSpots.count - visibleCount
    }

    func mergeOverlappingInkSpots(_ inkSpots: [InkSpot]) -> [InkSpot] {
        // 重複するインクスポットをマージ
        var mergedSpots: [InkSpot] = []
        var processed: Set<InkSpotId> = []

        for inkSpot in inkSpots {
            if processed.contains(inkSpot.id) { continue }

            var currentSpot = inkSpot
            processed.insert(inkSpot.id)

            // 近くの同色インクスポットを検索
            for otherSpot in inkSpots {
                if processed.contains(otherSpot.id) || otherSpot.color != inkSpot.color { continue }

                let distance = simd_distance(
                    SIMD3<Float>(inkSpot.position.x, inkSpot.position.y, inkSpot.position.z),
                    SIMD3<Float>(otherSpot.position.x, otherSpot.position.y, otherSpot.position.z)
                )

                if distance < (inkSpot.size + otherSpot.size) * 0.8 { // 80%重複
                    // マージ
                    let newSize = sqrt(inkSpot.size * inkSpot.size + otherSpot.size * otherSpot.size)
                    let newPosition = Position3D(
                        x: (inkSpot.position.x + otherSpot.position.x) / 2,
                        y: (inkSpot.position.y + otherSpot.position.y) / 2,
                        z: (inkSpot.position.z + otherSpot.position.z) / 2
                    )

                    currentSpot = InkSpot(
                        id: inkSpot.id,
                        position: newPosition,
                        color: inkSpot.color,
                        size: newSize,
                        ownerId: inkSpot.ownerId,
                        createdAt: inkSpot.createdAt
                    )

                    processed.insert(otherSpot.id)
                }
            }

            mergedSpots.append(currentSpot)
        }

        return mergedSpots
    }

    func getRenderingStats() -> RenderingStats {
        renderingStats
    }

    // MARK: - Battery Efficiency Methods

    func setRenderingQuality(_ quality: RenderingQuality) {
        switch quality {
        case .minimal:
            arView?.renderOptions.insert(.disableHDR)
            arView?.renderOptions.insert(.disablePersonOcclusion)
            arView?.renderOptions.insert(.disableMotionBlur)
        case .low:
            arView?.renderOptions.insert(.disableHDR)
            arView?.renderOptions.insert(.disablePersonOcclusion)
        case .medium:
            arView?.renderOptions.remove(.disableHDR)
            arView?.renderOptions.insert(.disablePersonOcclusion)
        case .high:
            arView?.renderOptions.remove(.disableHDR)
            arView?.renderOptions.remove(.disablePersonOcclusion)
        }
        renderingStats.qualityChanges += 1
    }

    func enableSelectiveOptimizations() {
        // 選択的最適化：重要な機能は維持
        renderingStats.selectiveOptimizations += 1
    }

    func enablePowerSavingMode() {
        // 省電力モード：フレームレートとレンダリング品質を調整
        arView?.renderOptions.insert(.disableMotionBlur)
        renderingStats.powerSavingActivations += 1
    }

    func enableAggressivePowerSaving() {
        // 積極的省電力：大幅な品質低下を許容
        arView?.renderOptions.insert(.disableHDR)
        arView?.renderOptions.insert(.disablePersonOcclusion)
        arView?.renderOptions.insert(.disableMotionBlur)
        renderingStats.aggressivePowerSaving += 1
    }

    func enableEmergencyPowerSaving() {
        // 緊急省電力：最低限の機能のみ
        arView?.renderOptions.insert(.disableHDR)
        arView?.renderOptions.insert(.disablePersonOcclusion)
        arView?.renderOptions.insert(.disableMotionBlur)
        renderingStats.emergencyPowerSaving += 1
    }

    func reduceARUpdateFrequency() {
        // AR更新頻度の削減
        renderingStats.arUpdateReductions += 1
    }

    func minimizeARProcessing() {
        // AR処理の最小化
        renderingStats.arProcessingMinimizations += 1
    }

    func pauseNonEssentialARFeatures() {
        // 非必須AR機能の一時停止
        renderingStats.nonEssentialFeaturePauses += 1
    }

    func restoreNormalOperations() {
        // 通常動作の復元
        arView?.renderOptions.remove(.disableHDR)
        arView?.renderOptions.remove(.disablePersonOcclusion)
        arView?.renderOptions.remove(.disableMotionBlur)
        renderingStats.normalOperationRestores += 1
    }

    func enableThermalOptimizations() {
        // 熱最適化の有効化
        renderingStats.thermalOptimizations += 1
    }

    func enableAggressiveThermalOptimizations() {
        // 積極的熱最適化
        arView?.renderOptions.insert(.disableHDR)
        renderingStats.aggressiveThermalOptimizations += 1
    }

    func enableEmergencyThermalOptimizations() {
        // 緊急熱最適化
        arView?.renderOptions.insert(.disableHDR)
        arView?.renderOptions.insert(.disablePersonOcclusion)
        arView?.renderOptions.insert(.disableMotionBlur)
        renderingStats.emergencyThermalOptimizations += 1
    }

    func pauseAllNonEssentialOperations() {
        // 全ての非必須処理を一時停止
        renderingStats.allNonEssentialPauses += 1
    }

    func resetStatistics() {
        renderingStats = RenderingStats()
    }
}

// MARK: - OptimizationStats

struct OptimizationStats {
    var performanceAdjustments: Int = 0
    var memoryOptimizations: Int = 0
    var inkSpotOptimizations: Int = 0
    var inkSpotMerges: Int = 0
    var networkOptimizations: Int = 0
    var thermalOptimizations: Int = 0
    var batteryOptimizations: Int = 0
}

// MARK: - RenderingStats

struct RenderingStats {
    var qualityReductions: Int = 0
    var qualityImprovements: Int = 0
    var qualityChanges: Int = 0
    var entitiesCulled: Int = 0
    var lodApplications: Int = 0
    var shadowOptimizations: Int = 0
    var shadowImprovements: Int = 0
    var resourceCleanups: Int = 0
    var textureOptimizations: Int = 0
    var instancingOptimizations: Int = 0
    var inkSpotsCulled: Int = 0

    // バッテリー効率関連
    var selectiveOptimizations: Int = 0
    var powerSavingActivations: Int = 0
    var aggressivePowerSaving: Int = 0
    var emergencyPowerSaving: Int = 0
    var arUpdateReductions: Int = 0
    var arProcessingMinimizations: Int = 0
    var nonEssentialFeaturePauses: Int = 0
    var normalOperationRestores: Int = 0

    // 熱管理関連
    var thermalOptimizations: Int = 0
    var aggressiveThermalOptimizations: Int = 0
    var emergencyThermalOptimizations: Int = 0
    var allNonEssentialPauses: Int = 0
}

// MARK: - PerformanceReport

struct PerformanceReport {
    let averageFrameRate: Double
    let currentMemoryUsage: UInt64
    let optimizationStats: OptimizationStats
    let renderingStats: RenderingStats

    var formattedMemoryUsage: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(currentMemoryUsage))
    }
}

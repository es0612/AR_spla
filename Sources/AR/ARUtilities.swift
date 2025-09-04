import ARKit
import Domain
import Foundation
import RealityKit

// MARK: - ARError

/// AR-related errors
enum ARError: Error, LocalizedError {
    case sessionFailed
    case trackingLimited
    case planeDetectionFailed
    case unsupportedDevice
    case gameFieldNotFound
    case coordinateConversionFailed

    var errorDescription: String? {
        switch self {
        case .sessionFailed:
            return "ARセッションの開始に失敗しました"
        case .trackingLimited:
            return "トラッキングが制限されています。デバイスを動かして環境をスキャンしてください"
        case .planeDetectionFailed:
            return "平面の検出に失敗しました。明るい場所で平らな面をスキャンしてください"
        case .unsupportedDevice:
            return "このデバイスはARをサポートしていません"
        case .gameFieldNotFound:
            return "ゲームフィールドが見つかりません。平面をスキャンしてください"
        case .coordinateConversionFailed:
            return "座標変換に失敗しました"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .sessionFailed:
            return "アプリを再起動してください"
        case .trackingLimited:
            return "デバイスをゆっくりと動かして環境をスキャンしてください"
        case .planeDetectionFailed:
            return "明るい場所で、テクスチャのある平らな面をスキャンしてください"
        case .unsupportedDevice:
            return "ARKit対応デバイスをご利用ください"
        case .gameFieldNotFound:
            return "カメラを平らな面に向けてスキャンしてください"
        case .coordinateConversionFailed:
            return "ゲームを再開してください"
        }
    }
}

// MARK: - ARSessionState

/// AR session state
public enum ARSessionState {
    case notStarted
    case starting
    case running
    case paused
    case interrupted
    case failed(Error)

    var isActive: Bool {
        switch self {
        case .running:
            return true
        default:
            return false
        }
    }
}

// MARK: - GameFieldState

/// Game field state
public enum GameFieldState: Equatable {
    case notDetected
    case detecting
    case detected(ARAnchor)
    case setup(ARAnchor)
    case lost

    var isReady: Bool {
        switch self {
        case .setup:
            return true
        default:
            return false
        }
    }

    var anchor: ARAnchor? {
        switch self {
        case let .detected(anchor), let .setup(anchor):
            return anchor
        default:
            return nil
        }
    }
}

// MARK: - ARCoordinateSystem

/// AR coordinate system utilities
enum ARCoordinateSystem {
    /// Convert AR world coordinates to normalized game coordinates
    /// Game field is normalized to -1.0 to 1.0 in both X and Z axes
    static func arToGame(_ arPosition: SIMD4<Float>, fieldAnchor: ARAnchor, fieldSize: CGSize) -> Position3D? {
        guard let planeAnchor = fieldAnchor as? ARPlaneAnchor else { return nil }

        // Get the field transform
        let fieldTransform = planeAnchor.transform

        // Convert AR position to field-relative coordinates
        let fieldInverse = fieldTransform.inverse
        let relativePosition = fieldInverse * arPosition

        // Normalize to game coordinates (-1.0 to 1.0)
        let normalizedX = (relativePosition.x / Float(fieldSize.width)) * 2.0
        let normalizedZ = (relativePosition.z / Float(fieldSize.height)) * 2.0

        return Position3D(
            x: normalizedX,
            y: relativePosition.y,
            z: normalizedZ
        )
    }

    /// Convert normalized game coordinates to AR world coordinates
    static func gameToAR(_ gamePosition: Position3D, fieldAnchor: ARAnchor, fieldSize: CGSize) -> SIMD4<Float>? {
        guard let planeAnchor = fieldAnchor as? ARPlaneAnchor else { return nil }

        // Convert normalized coordinates to field-relative coordinates
        let fieldX = (gamePosition.x / 2.0) * Float(fieldSize.width)
        let fieldZ = (gamePosition.z / 2.0) * Float(fieldSize.height)

        // Create field-relative position
        let fieldRelativePosition = SIMD4<Float>(fieldX, gamePosition.y, fieldZ, 1.0)

        // Transform to world coordinates
        let worldPosition = planeAnchor.transform * fieldRelativePosition

        return worldPosition
    }

    /// Check if a position is within the game field bounds
    static func isWithinGameField(_ position: Position3D) -> Bool {
        abs(position.x) <= 1.0 && abs(position.z) <= 1.0
    }

    /// Convert screen coordinates to AR world ray
    static func screenToWorldRay(_ screenPoint: CGPoint, in arView: ARView) -> (origin: SIMD3<Float>, direction: SIMD3<Float>)? {
        guard let raycastQuery = arView.makeRaycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .horizontal) else {
            return nil
        }

        return (origin: raycastQuery.origin, direction: raycastQuery.direction)
    }

    /// Perform raycast from screen point to find world position
    static func screenToWorldPosition(_ screenPoint: CGPoint, in arView: ARView) -> SIMD4<Float>? {
        let results = arView.raycast(from: screenPoint, allowing: .estimatedPlane, alignment: .horizontal)
        return results.first?.worldTransform.columns.3
    }

    /// Calculate distance between two positions in AR space
    static func distance(from: SIMD4<Float>, to: SIMD4<Float>) -> Float {
        let dx = from.x - to.x
        let dy = from.y - to.y
        let dz = from.z - to.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }

    /// Interpolate between two AR positions
    static func interpolate(from: SIMD4<Float>, to: SIMD4<Float>, factor: Float) -> SIMD4<Float> {
        let clampedFactor = max(0.0, min(1.0, factor))
        return from + (to - from) * clampedFactor
    }

    /// Convert AR transform to game field relative transform
    static func arTransformToFieldRelative(_ transform: simd_float4x4, fieldAnchor: ARAnchor) -> simd_float4x4? {
        guard let planeAnchor = fieldAnchor as? ARPlaneAnchor else { return nil }

        let fieldInverse = planeAnchor.transform.inverse
        return fieldInverse * transform
    }

    /// Convert field relative transform to AR world transform
    static func fieldRelativeToARTransform(_ transform: simd_float4x4, fieldAnchor: ARAnchor) -> simd_float4x4? {
        guard let planeAnchor = fieldAnchor as? ARPlaneAnchor else { return nil }

        return planeAnchor.transform * transform
    }
}

// MARK: - ARTrackingQuality

/// AR tracking quality assessment
public enum ARTrackingQuality {
    static func assess(_ frame: ARFrame) -> TrackingQuality {
        let camera = frame.camera

        switch camera.trackingState {
        case .normal:
            return .good
        case let .limited(reason):
            return .limited(reason)
        case .notAvailable:
            return .poor
        }
    }

    public enum TrackingQuality {
        case good
        case limited(ARCamera.TrackingState.Reason)
        case poor

        var isGoodEnoughForGameplay: Bool {
            switch self {
            case .good:
                return true
            case let .limited(reason):
                // Some limited tracking states are still acceptable
                switch reason {
                case .initializing, .relocalizing:
                    return false
                case .excessiveMotion, .insufficientFeatures:
                    return true // Can still play, but with reduced quality
                @unknown default:
                    return false
                }
            case .poor:
                return false
            }
        }

        var userMessage: String? {
            switch self {
            case .good:
                return nil
            case let .limited(reason):
                switch reason {
                case .initializing:
                    return "ARを初期化中です..."
                case .excessiveMotion:
                    return "デバイスをゆっくりと動かしてください"
                case .insufficientFeatures:
                    return "テクスチャのある面をスキャンしてください"
                case .relocalizing:
                    return "位置を再計算中です..."
                @unknown default:
                    return "トラッキングが制限されています"
                }
            case .poor:
                return "ARトラッキングが利用できません"
            }
        }
    }
}

// MARK: - ARPerformanceMonitor

/// AR performance monitoring
class ARPerformanceMonitor {
    private var frameCount = 0
    private var lastFrameTime = CACurrentMediaTime()
    private var frameRates: [Double] = []

    func recordFrame() {
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastFrameTime

        if deltaTime > 0 {
            let frameRate = 1.0 / deltaTime
            frameRates.append(frameRate)

            // Keep only recent frame rates (last 60 frames)
            if frameRates.count > 60 {
                frameRates.removeFirst()
            }
        }

        lastFrameTime = currentTime
        frameCount += 1
    }

    var averageFrameRate: Double {
        guard !frameRates.isEmpty else { return 0 }
        return frameRates.reduce(0, +) / Double(frameRates.count)
    }

    var isPerformanceGood: Bool {
        averageFrameRate >= 30.0 // Target 30 FPS minimum
    }

    func reset() {
        frameCount = 0
        frameRates.removeAll()
        lastFrameTime = CACurrentMediaTime()
    }
}

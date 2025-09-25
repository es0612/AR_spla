import ARKit
import AVFoundation
import Domain
import RealityKit
import UIKit

// MARK: - ARViewController

/// ARViewController manages the AR session and game field setup
class ARViewController: UIViewController {
    // MARK: - Properties

    private var arView: ARView!
    private var arGameCoordinator: ARGameCoordinator!
    private weak var gameState: GameState?
    private weak var errorManager: ErrorManager?

    // Device compatibility and AR capabilities
    private let deviceCompatibility: DeviceCompatibilityManager
    private let arCapabilityService: ARCapabilityService

    // Player shot tracking for cooldown
    private var playerLastShotTimes: [PlayerId: Date] = [:]

    // Delegates
    weak var delegate: ARViewControllerDelegate?

    // MARK: - Initialization

    init(deviceCompatibility: DeviceCompatibilityManager) {
        self.deviceCompatibility = deviceCompatibility
        arCapabilityService = ARCapabilityService(deviceCompatibility: deviceCompatibility)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // デバイス対応チェック
        guard deviceCompatibility.isDeviceSupported() else {
            errorManager?.handleError(.arUnsupportedDevice)
            return
        }

        setupARView()
        setupARGameCoordinator()
        setupGestures()
        applyDeviceOptimizations()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arGameCoordinator.stopARSession()
    }

    // MARK: - Public Methods

    /// Configure the AR controller with game state and error manager
    func configure(with gameState: GameState, errorManager: ErrorManager) {
        self.gameState = gameState
        self.errorManager = errorManager
    }

    /// Start the AR session
    func startARSession() {
        // ARKitサポートチェック
        guard ARWorldTrackingConfiguration.isSupported else {
            errorManager?.handleError(.arUnsupportedDevice)
            return
        }

        // カメラアクセス権限チェック
        checkCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startARSessionWithOptimalConfiguration()
                } else {
                    self?.errorManager?.handleError(.arCameraAccessDenied)
                }
            }
        }
    }

    /// デバイスに最適化されたAR設定でセッションを開始
    private func startARSessionWithOptimalConfiguration() {
        let configuration = arCapabilityService.getOptimalConfiguration()

        // LiDARの有無に応じた設定調整
        if arCapabilityService.capabilities.hasLiDAR {
            print("LiDAR detected - enabling enhanced AR features")
        } else {
            print("No LiDAR - using traditional plane detection")
        }

        arGameCoordinator.startARSession(with: configuration)
    }

    /// カメラアクセス権限をチェックする
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    /// Stop the AR session
    func stopARSession() {
        arGameCoordinator.stopARSession()
    }

    /// Handle tap gesture for ink shooting
    func handleTap(at location: CGPoint) {
        guard let gameState = gameState,
              gameState.isGameActive,
              let currentPlayer = gameState.players.first else { return }

        // Check if player can shoot ink (cooldown, active state, etc.)
        guard canPlayerShootInk(currentPlayer) else { return }

        // Use AR game coordinator to handle tap
        let success = arGameCoordinator.handleTap(at: location, for: currentPlayer)

        if success {
            // Update last shot time for cooldown
            updatePlayerLastShotTime(currentPlayer.id)

            // Provide haptic feedback
            provideHapticFeedback()
        }
    }

    /// Check if player can shoot ink (considering cooldown and state)
    private func canPlayerShootInk(_ player: Player) -> Bool {
        // Check if player is active
        guard player.isActive else { return false }

        // Check cooldown (0.5 seconds between shots)
        let cooldownDuration: TimeInterval = 0.5
        if let lastShotTime = playerLastShotTimes[player.id] {
            let timeSinceLastShot = Date().timeIntervalSince(lastShotTime)
            if timeSinceLastShot < cooldownDuration {
                return false
            }
        }

        return true
    }

    /// Update player's last shot time
    private func updatePlayerLastShotTime(_ playerId: PlayerId) {
        playerLastShotTimes[playerId] = Date()
    }

    /// Provide haptic feedback for ink shooting
    private func provideHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    // MARK: - Private Methods

    private func setupARView() {
        arView = ARView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)

        // デバイスに応じたパフォーマンス最適化を適用
        arCapabilityService.applyPerformanceOptimizations(to: arView)
    }

    private func setupARGameCoordinator() {
        arGameCoordinator = ARGameCoordinator(
            arView: arView,
            deviceCompatibility: deviceCompatibility,
            arCapabilityService: arCapabilityService
        )
        arGameCoordinator.delegate = self
    }

    /// デバイス固有の最適化を適用
    private func applyDeviceOptimizations() {
        let performanceSettings = deviceCompatibility.getRecommendedSettings()

        // パフォーマンス設定に応じた調整
        switch performanceSettings.renderQuality {
        case .high:
            // 高品質設定
            arView.environment.sceneUnderstanding.options = [.physics, .occlusion, .receivesLighting]
        case .medium:
            // 中品質設定
            arView.environment.sceneUnderstanding.options = [.occlusion]
        case .low:
            // 低品質設定（最小限）
            arView.environment.sceneUnderstanding.options = []
        }

        // オクルージョン設定
        let occlusionSettings = arCapabilityService.getOcclusionSettings()
        if occlusionSettings.enabled {
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
        }
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        arView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)
        handleTap(at: location)
    }

    /// Get the AR game coordinator for external access
    var gameCoordinator: ARGameCoordinator {
        arGameCoordinator
    }
}

// MARK: ARGameCoordinatorDelegate

extension ARViewController: ARGameCoordinatorDelegate {
    func arGameCoordinatorDidStartSession(_: ARGameCoordinator) {
        delegate?.arViewControllerDidStartSession(self)
    }

    func arGameCoordinatorDidStopSession(_: ARGameCoordinator) {
        delegate?.arViewControllerDidStopSession(self)
    }

    func arGameCoordinatorWasInterrupted(_: ARGameCoordinator) {
        delegate?.arViewControllerWasInterrupted(self)
    }

    func arGameCoordinatorInterruptionEnded(_: ARGameCoordinator) {
        delegate?.arViewControllerInterruptionEnded(self)
    }

    func arGameCoordinator(_: ARGameCoordinator, didSetupGameField anchor: ARAnchor) {
        delegate?.arViewController(self, didSetupGameField: anchor)
    }

    func arGameCoordinator(_: ARGameCoordinator, didUpdateGameField _: ARAnchor) {
        // Optional: Handle field updates
    }

    func arGameCoordinatorDidLoseGameField(_ coordinator: ARGameCoordinator) {
        if let anchor = coordinator.currentFieldAnchor {
            delegate?.arViewController(self, didLoseGameField: anchor)
        }
    }

    func arGameCoordinator(_: ARGameCoordinator, didShootInk inkSpot: InkSpot, at position: Position3D) {
        delegate?.arViewController(self, didShootInkAt: position, color: inkSpot.color)

        // Update game state and handle network synchronization
        Task { @MainActor in
            await gameState?.shootInk(
                playerId: inkSpot.ownerId,
                at: position,
                size: inkSpot.size
            )

            // Notify delegate for network synchronization
            delegate?.arViewController(self, didAddInkSpot: position, color: inkSpot.color)
        }
    }

    func arGameCoordinator(_: ARGameCoordinator, didDetectPlayerCollision playerId: PlayerId, at position: Position3D, effect: PlayerCollisionEffect) {
        delegate?.arViewController(self, didDetectPlayerCollision: playerId, at: position, effect: effect)

        // Handle player collision effects
        Task { @MainActor in
            await handlePlayerCollisionEffects(playerId: playerId, at: position, effect: effect)
        }
    }

    func arGameCoordinator(_: ARGameCoordinator, didProcessInkSpotOverlap inkSpot: InkSpot, overlaps: [(InkSpot, InkSpotOverlapResult)]) {
        // Handle ink spot overlap processing
        Task { @MainActor in
            await gameState?.handleInkSpotOverlap(inkSpot: inkSpot, overlaps: overlaps)
        }

        // Notify delegate
        delegate?.arViewController(self, didProcessInkSpotOverlap: inkSpot, overlaps: overlaps)
    }

    /// Handle the effects of a player collision with ink
    private func handlePlayerCollisionEffects(playerId: PlayerId, at position: Position3D, effect: PlayerCollisionEffect) async {
        // Provide haptic feedback for collision
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        // Update game state with collision effect
        await gameState?.handlePlayerCollision(playerId: playerId, effect: effect)

        // Could add visual effects here (screen flash, particle effects, etc.)
        print("Player \(playerId) hit by ink at position \(position) with effect: \(effect)")
    }

    func arGameCoordinator(_: ARGameCoordinator, didUpdateTrackingQuality quality: ARTrackingQuality.TrackingQuality) {
        // Optional: Handle tracking quality updates
        if quality.userMessage != nil {
            // Could show tracking quality message to user
        }
    }

    func arGameCoordinator(_: ARGameCoordinator, didFailWithError error: Error) {
        // エラーマネージャーでARエラーを処理
        errorManager?.handleARError(error)
        delegate?.arViewController(self, didFailWithError: error)
    }

    func arGameCoordinator(_ coordinator: ARGameCoordinator, didUpdatePlayerPosition position: Position3D) {
        // Update current player position in game state
        Task { @MainActor in
            guard let gameState = gameState,
                  let currentPlayer = gameState.players.first else { return }

            // Create updated player with new position
            let updatedPlayer = Player(
                id: currentPlayer.id,
                name: currentPlayer.name,
                color: currentPlayer.color,
                position: position
            )

            // Update player in game state
            if let playerIndex = gameState.players.firstIndex(where: { $0.id == currentPlayer.id }) {
                gameState.players[playerIndex] = updatedPlayer
            }

            // Update collision detector with new position
            coordinator.updatePlayer(updatedPlayer)
        }
    }

    func arGameCoordinatorDidCompleteePlaneDetection(_: ARGameCoordinator) {
        delegate?.arViewControllerDidCompletePlaneDetection(self)
    }

    func arGameCoordinator(_: ARGameCoordinator, didMergeInkSpots originalSpots: [InkSpot], into mergedSpot: InkSpot) {
        // Handle ink spot merging
        Task { @MainActor in
            await gameState?.handleInkSpotMerge(originalSpots: originalSpots, mergedSpot: mergedSpot)
        }

        // Notify delegate
        delegate?.arViewController(self, didMergeInkSpots: originalSpots, into: mergedSpot)
    }

    func arGameCoordinator(_: ARGameCoordinator, didCreateInkConflict newSpot: InkSpot, with existingSpot: InkSpot, overlapArea: Float) {
        // Handle ink spot conflicts
        Task { @MainActor in
            await gameState?.handleInkSpotConflict(newSpot: newSpot, existingSpot: existingSpot, overlapArea: overlapArea)
        }

        // Notify delegate
        delegate?.arViewController(self, didCreateInkConflict: newSpot, with: existingSpot, overlapArea: overlapArea)
    }
}

// MARK: - ARViewControllerDelegate

protocol ARViewControllerDelegate: AnyObject {
    func arViewControllerDidStartSession(_ controller: ARViewController)
    func arViewControllerDidStopSession(_ controller: ARViewController)
    func arViewControllerWasInterrupted(_ controller: ARViewController)
    func arViewControllerInterruptionEnded(_ controller: ARViewController)

    func arViewController(_ controller: ARViewController, didDetectGameField anchor: ARAnchor)
    func arViewController(_ controller: ARViewController, didSetupGameField anchor: ARAnchor)
    func arViewController(_ controller: ARViewController, didLoseGameField anchor: ARAnchor)
    func arViewController(_ controller: ARViewController, didUpdateCoverage coverage: Float)

    func arViewController(_ controller: ARViewController, didShootInkAt position: Position3D, color: PlayerColor)
    func arViewController(_ controller: ARViewController, didAddInkSpot position: Position3D, color: PlayerColor)
    func arViewController(_ controller: ARViewController, didDetectCollision playerId: PlayerId, at position: Position3D)

    func arViewController(_ controller: ARViewController, didFailWithError error: Error)

    // MARK: - Collision Detection Methods

    func arViewController(_ controller: ARViewController, didDetectPlayerCollision playerId: PlayerId, at position: Position3D, effect: PlayerCollisionEffect)
    func arViewController(_ controller: ARViewController, didProcessInkSpotOverlap inkSpot: InkSpot, overlaps: [(InkSpot, InkSpotOverlapResult)])
    func arViewController(_ controller: ARViewController, didMergeInkSpots originalSpots: [InkSpot], into mergedSpot: InkSpot)
    func arViewController(_ controller: ARViewController, didCreateInkConflict newSpot: InkSpot, with existingSpot: InkSpot, overlapArea: Float)
    func arViewController(_ controller: ARViewController, didUpdatePlayerPosition position: Position3D)

    // Guidance methods
    func arViewControllerDidCompletePlaneDetection(_ controller: ARViewController)
}

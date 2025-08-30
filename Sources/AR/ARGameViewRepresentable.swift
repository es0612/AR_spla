import SwiftUI
import ARKit
import RealityKit
import Domain

struct ARGameViewRepresentable: UIViewRepresentable {
    let gameState: GameState?
    
    init(gameState: GameState? = nil) {
        self.gameState = gameState
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // AR設定
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        arView.session.run(configuration)
        
        // デリゲート設定
        arView.session.delegate = context.coordinator
        
        // タップジェスチャー追加
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // GameStateをCoordinatorに渡す
        context.coordinator.gameState = gameState
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // GameStateの更新をCoordinatorに反映
        context.coordinator.gameState = gameState
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var gameState: GameState?
        private var inkSpotCount = 0
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView,
                  let gameState = gameState,
                  gameState.isGameActive else { return }
            
            let location = gesture.location(in: arView)
            
            // レイキャストを使用して3D位置を取得
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                // 3D位置を取得
                let worldPosition = firstResult.worldTransform.columns.3
                let position3D = Position3D(
                    x: worldPosition.x,
                    y: worldPosition.y,
                    z: worldPosition.z
                )
                
                // 現在のプレイヤーを取得
                guard let currentPlayer = gameState.players.first else { return }
                
                // GameStateを通じてインクを発射
                Task { @MainActor in
                    await gameState.shootInk(
                        playerId: currentPlayer.id,
                        at: position3D,
                        size: 0.1
                    )
                }
                
                // AR空間にインクスポットを配置
                placeInkSpot(at: firstResult.worldTransform, color: currentPlayer.color, in: arView)
            }
        }
        
        private func placeInkSpot(at transform: simd_float4x4, color: PlayerColor, in arView: ARView) {
            // インクスポットのエンティティを作成
            let inkSpot = ModelEntity(mesh: .generateSphere(radius: 0.05))
            
            // プレイヤーの色に応じてマテリアルを設定
            var material = SimpleMaterial()
            material.color = .init(tint: uiColor(for: color))
            material.roughness = .init(floatLiteral: 0.3)
            material.metallic = .init(floatLiteral: 0.1)
            inkSpot.model?.materials = [material]
            
            // 位置を設定
            inkSpot.transform.matrix = transform
            
            // アンカーエンティティを作成してシーンに追加
            let anchorEntity = AnchorEntity(world: transform)
            anchorEntity.addChild(inkSpot)
            arView.scene.addAnchor(anchorEntity)
            
            // 簡単なアニメーション
            inkSpot.transform.scale = SIMD3<Float>(0.1, 0.1, 0.1)
            let scaleAnimation = FromToByAnimation<Transform>(
                from: Transform(scale: SIMD3<Float>(0.1, 0.1, 0.1)),
                to: Transform(scale: SIMD3<Float>(1.0, 1.0, 1.0)),
                duration: 0.3,
                timing: .easeOut,
                bindTarget: .transform
            )
            if let animationResource = try? AnimationResource.generate(with: scaleAnimation) {
                inkSpot.playAnimation(animationResource)
            }
            
            // インクスポット数をカウント
            inkSpotCount += 1
        }
        
        private func uiColor(for playerColor: PlayerColor) -> UIColor {
            switch playerColor {
            case .blue:
                return .systemBlue
            case .red:
                return .systemRed
            case .green:
                return .systemGreen
            case .yellow:
                return .systemYellow
            }
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("ARSession failed with error: \(error.localizedDescription)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("ARSession was interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("ARSession interruption ended")
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    print("Detected plane: \(planeAnchor.planeExtent)")
                }
            }
        }
    }
}
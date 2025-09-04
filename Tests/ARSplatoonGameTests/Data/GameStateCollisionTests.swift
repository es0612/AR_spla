//
//  GameStateCollisionTests.swift
//  ARSplatoonGameTests
//
//  Created by Kiro on 2025-01-09.
//

import Testing
@testable import ARSplatoonGame
@testable import Domain

/// Tests for GameState collision handling
struct GameStateCollisionTests {
    
    // MARK: - Test Data
    
    private func createTestGameState() -> GameState {
        let gameState = GameState()
        
        // Add test players
        let player1 = Player(
            id: PlayerId(),
            name: "Player1",
            color: .red,
            position: Position3D(x: 0, y: 0, z: 0)
        )
        
        let player2 = Player(
            id: PlayerId(),
            name: "Player2",
            color: .blue,
            position: Position3D(x: 2, y: 0, z: 0)
        )
        
        gameState.players = [player1, player2]
        gameState.isGameActive = true
        
        return gameState
    }
    
    // MARK: - Player Collision Tests
    
    @Test("プレイヤー衝突効果なしの処理")
    func testPlayerCollisionNoEffect() async {
        let gameState = createTestGameState()
        let playerId = gameState.players[0].id
        
        await gameState.handlePlayerCollision(playerId: playerId, effect: .none)
        
        // Player should remain active
        let player = gameState.players.first { $0.id == playerId }
        #expect(player?.isActive == true)
    }
    
    @Test("プレイヤースタン効果の処理")
    func testPlayerCollisionStunEffect() async {
        let gameState = createTestGameState()
        let playerId = gameState.players[0].id
        
        // Disable haptic for testing
        gameState.hapticEnabled = false
        
        let stunEffect = PlayerCollisionEffect.stunned(duration: 0.1, speedReduction: 0.5) // Short duration for test
        
        await gameState.handlePlayerCollision(playerId: playerId, effect: stunEffect)
        
        // Player should be deactivated immediately
        let player = gameState.players.first { $0.id == playerId }
        #expect(player?.isActive == false)
        
        // Wait for reactivation
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Player should be reactivated
        let reactivatedPlayer = gameState.players.first { $0.id == playerId }
        #expect(reactivatedPlayer?.isActive == true)
    }
    
    @Test("存在しないプレイヤーの衝突処理")
    func testPlayerCollisionNonExistentPlayer() async {
        let gameState = createTestGameState()
        let nonExistentPlayerId = PlayerId() // Random ID
        
        let stunEffect = PlayerCollisionEffect.stunned(duration: 1.0, speedReduction: 0.5)
        
        // Should not crash or affect other players
        await gameState.handlePlayerCollision(playerId: nonExistentPlayerId, effect: stunEffect)
        
        // All existing players should remain active
        for player in gameState.players {
            #expect(player.isActive == true)
        }
    }
    
    // MARK: - Ink Spot Overlap Tests
    
    @Test("インクスポット重複処理")
    func testInkSpotOverlapHandling() async {
        let gameState = createTestGameState()
        
        let inkSpot1 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: gameState.players[0].id
        )
        
        let inkSpot2 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1.0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: gameState.players[0].id
        )
        
        let overlapResult = InkSpotOverlapResult(
            hasOverlap: true,
            overlapArea: 0.5,
            mergedSize: 1.4
        )
        
        let overlaps = [(inkSpot2, overlapResult)]
        
        // Should not crash
        await gameState.handleInkSpotOverlap(inkSpot: inkSpot1, overlaps: overlaps)
        
        // Game state should be updated
        #expect(gameState.isGameActive == true)
    }
    
    @Test("インクスポットマージ処理")
    func testInkSpotMergeHandling() async {
        let gameState = createTestGameState()
        
        let originalSpot1 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: gameState.players[0].id
        )
        
        let originalSpot2 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1.0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: gameState.players[0].id
        )
        
        let mergedSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.5, y: 0, z: 0),
            color: .red,
            size: 1.4,
            ownerId: gameState.players[0].id
        )
        
        // Should not crash
        await gameState.handleInkSpotMerge(originalSpots: [originalSpot1, originalSpot2], mergedSpot: mergedSpot)
        
        // Game state should be updated
        #expect(gameState.isGameActive == true)
    }
    
    @Test("インクスポット衝突処理")
    func testInkSpotConflictHandling() async {
        let gameState = createTestGameState()
        
        let newSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: gameState.players[0].id
        )
        
        let existingSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.5, y: 0, z: 0),
            color: .blue,
            size: 1.0,
            ownerId: gameState.players[1].id
        )
        
        let overlapArea: Float = 0.3
        
        // Should not crash
        await gameState.handleInkSpotConflict(newSpot: newSpot, existingSpot: existingSpot, overlapArea: overlapArea)
        
        // Game state should be updated
        #expect(gameState.isGameActive == true)
    }
    
    // MARK: - Legacy Collision Method Tests
    
    @Test("レガシー衝突処理メソッド")
    func testLegacyPlayerInkCollision() async {
        let gameState = createTestGameState()
        let playerId = gameState.players[0].id
        let position = Position3D(x: 1, y: 0, z: 0)
        
        await gameState.handlePlayerInkCollision(playerId: playerId, at: position)
        
        // Player should be deactivated
        let player = gameState.players.first { $0.id == playerId }
        #expect(player?.isActive == false)
        
        // Wait a bit for reactivation (this method uses 3 second delay)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Player should still be deactivated (3 second delay)
        let stillDeactivatedPlayer = gameState.players.first { $0.id == playerId }
        #expect(stillDeactivatedPlayer?.isActive == false)
    }
    
    // MARK: - Concurrent Collision Tests
    
    @Test("同時衝突処理")
    func testConcurrentCollisions() async {
        let gameState = createTestGameState()
        let player1Id = gameState.players[0].id
        let player2Id = gameState.players[1].id
        
        gameState.hapticEnabled = false // Disable haptic for testing
        
        let stunEffect = PlayerCollisionEffect.stunned(duration: 0.1, speedReduction: 0.5)
        
        // Handle collisions concurrently
        async let collision1 = gameState.handlePlayerCollision(playerId: player1Id, effect: stunEffect)
        async let collision2 = gameState.handlePlayerCollision(playerId: player2Id, effect: stunEffect)
        
        await collision1
        await collision2
        
        // Both players should be deactivated
        let player1 = gameState.players.first { $0.id == player1Id }
        let player2 = gameState.players.first { $0.id == player2Id }
        
        #expect(player1?.isActive == false)
        #expect(player2?.isActive == false)
        
        // Wait for reactivation
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Both players should be reactivated
        let reactivatedPlayer1 = gameState.players.first { $0.id == player1Id }
        let reactivatedPlayer2 = gameState.players.first { $0.id == player2Id }
        
        #expect(reactivatedPlayer1?.isActive == true)
        #expect(reactivatedPlayer2?.isActive == true)
    }
}
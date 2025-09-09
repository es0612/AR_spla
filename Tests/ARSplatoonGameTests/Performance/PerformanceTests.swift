//
//  PerformanceTests.swift
//  ARSplatoonGameTests
//
//  Created by Kiro on 2025-01-09.
//

import Testing
import XCTest
import ARKit
import RealityKit
@testable import ARSplatoonGame
@testable import Domain
@testable import Infrastructure

/// Performance tests for critical game components
struct PerformanceTests {
    
    // MARK: - AR Performance Tests
    
    @Test("AR描画パフォーマンステスト")
    func testARRenderingPerformance() async throws {
        let arView = ARView()
        let coordinator = ARGameCoordinator(arView: arView)
        
        // 大量のインクスポット生成
        var inkSpots: [InkSpot] = []
        for i in 0..<1000 {
            let inkSpot = InkSpot(
                id: InkSpotId(),
                position: Position3D(
                    x: Float.random(in: -10...10),
                    y: 0,
                    z: Float.random(in: -10...10)
                ),
                color: i % 2 == 0 ? .red : .blue,
                size: Float.random(in: 0.1...1.0),
                ownerId: PlayerId()
            )
            inkSpots.append(inkSpot)
        }
        
        // パフォーマンス測定
        let startTime = Date()
        
        for inkSpot in inkSpots {
            _ = coordinator.addInkSpot(inkSpot)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // パフォーマンス要件: 1000個のインクスポット追加が2秒以内
        #expect(duration < 2.0)
        
        print("AR描画パフォーマンス: \(inkSpots.count)個のインクスポットを\(String(format: "%.3f", duration))秒で処理")
    }
    
    @Test("AR衝突判定パフォーマンステスト")
    func testARCollisionDetectionPerformance() async throws {
        let arView = ARView()
        let coordinator = ARGameCoordinator(arView: arView)
        
        // プレイヤー設定
        let players = [
            Player(id: PlayerId(), name: "Player1", color: .red, position: Position3D(x: 0, y: 0, z: 0)),
            Player(id: PlayerId(), name: "Player2", color: .blue, position: Position3D(x: 5, y: 0, z: 5))
        ]
        
        for player in players {
            coordinator.updatePlayer(player)
        }
        
        // 大量のインクスポット生成（衝突判定対象）
        var inkSpots: [InkSpot] = []
        for i in 0..<500 {
            let inkSpot = InkSpot(
                id: InkSpotId(),
                position: Position3D(
                    x: Float.random(in: -2...2),
                    y: 0,
                    z: Float.random(in: -2...2)
                ),
                color: i % 2 == 0 ? .red : .blue,
                size: 0.5,
                ownerId: players[i % 2].id
            )
            inkSpots.append(inkSpot)
        }
        
        // 衝突判定パフォーマンス測定
        let startTime = Date()
        
        for inkSpot in inkSpots {
            _ = coordinator.addInkSpot(inkSpot)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // パフォーマンス要件: 500個のインクスポット衝突判定が1秒以内
        #expect(duration < 1.0)
        
        print("AR衝突判定パフォーマンス: \(inkSpots.count)個のインクスポットの衝突判定を\(String(format: "%.3f", duration))秒で処理")
    }
    
    // MARK: - Network Performance Tests
    
    @Test("ネットワーク通信パフォーマンステスト")
    func testNetworkPerformance() async throws {
        let sessionManager = MultiplayerSessionManager(displayName: "TestPlayer")
        
        // 大量のメッセージ生成
        var messages: [NetworkGameMessage] = []
        for i in 0..<100 {
            let inkSpot = InkSpot(
                id: InkSpotId(),
                position: Position3D(x: Float(i), y: 0, z: 0),
                color: .red,
                size: 0.5,
                ownerId: PlayerId()
            )
            
            let message = NetworkGameMessage(
                type: .inkShot,
                data: try JSONEncoder().encode(inkSpot),
                senderId: "player1",
                timestamp: Date()
            )
            messages.append(message)
        }
        
        // ネットワーク送信パフォーマンス測定
        let startTime = Date()
        
        for message in messages {
            _ = sessionManager.sendMessage(message)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // パフォーマンス要件: 100個のメッセージ送信が0.5秒以内
        #expect(duration < 0.5)
        
        print("ネットワーク通信パフォーマンス: \(messages.count)個のメッセージを\(String(format: "%.3f", duration))秒で送信")
    }
    
    @Test("バッチ処理パフォーマンステスト")
    func testBatchProcessingPerformance() async throws {
        let sessionManager = MultiplayerSessionManager(displayName: "TestPlayer")
        let batchProcessor = InkDataBatchProcessor(sessionManager: sessionManager)
        
        // 大量のインクデータ生成
        var inkSpots: [InkSpot] = []
        for i in 0..<200 {
            let inkSpot = InkSpot(
                id: InkSpotId(),
                position: Position3D(
                    x: Float(i % 20),
                    y: 0,
                    z: Float(i / 20)
                ),
                color: i % 2 == 0 ? .red : .blue,
                size: 0.3,
                ownerId: PlayerId()
            )
            inkSpots.append(inkSpot)
        }
        
        // バッチ処理パフォーマンス測定
        let startTime = Date()
        
        await batchProcessor.startBatching()
        
        for inkSpot in inkSpots {
            await batchProcessor.addInkSpot(inkSpot)
        }
        
        _ = await batchProcessor.sendBatch()
        await batchProcessor.stopBatching()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // パフォーマンス要件: 200個のインクスポットのバッチ処理が1秒以内
        #expect(duration < 1.0)
        
        print("バッチ処理パフォーマンス: \(inkSpots.count)個のインクスポットのバッチ処理を\(String(format: "%.3f", duration))秒で完了")
    }
    
    // MARK: - Game Logic Performance Tests
    
    @Test("スコア計算パフォーマンステスト")
    func testScoreCalculationPerformance() async throws {
        let gameState = GameState()
        
        // プレイヤー追加
        let player1 = Player(id: PlayerId(), name: "Player1", color: .red, position: Position3D(x: 0, y: 0, z: 0))
        let player2 = Player(id: PlayerId(), name: "Player2", color: .blue, position: Position3D(x: 5, y: 0, z: 5))
        
        gameState.addPlayer(player1)
        gameState.addPlayer(player2)
        
        // 大量のインクスポット追加
        for i in 0..<1000 {
            let inkSpot = InkSpot(
                id: InkSpotId(),
                position: Position3D(
                    x: Float.random(in: -10...10),
                    y: 0,
                    z: Float.random(in: -10...10)
                ),
                color: i % 2 == 0 ? .red : .blue,
                size: Float.random(in: 0.1...1.0),
                ownerId: i % 2 == 0 ? player1.id : player2.id
            )
            gameState.addInkSpot(inkSpot)
        }
        
        // スコア計算パフォーマンス測定
        let startTime = Date()
        
        let score1 = gameState.calculatePlayerScore(player1.id)
        let score2 = gameState.calculatePlayerScore(player2.id)
        let winner = gameState.determineWinner()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // パフォーマンス要件: 1000個のインクスポットのスコア計算が0.1秒以内
        #expect(duration < 0.1)
        #expect(score1 >= 0)
        #expect(score2 >= 0)
        #expect(winner != nil)
        
        print("スコア計算パフォーマンス: 1000個のインクスポットのスコア計算を\(String(format: "%.3f", duration))秒で完了")
    }
    
    @Test("ゲーム状態更新パフォーマンステスト")
    func testGameStateUpdatePerformance() async throws {
        let gameState = GameState()
        gameState.initializeGame()
        
        // プレイヤー追加
        let players = (0..<10).map { i in
            Player(
                id: PlayerId(),
                name: "Player\(i)",
                color: i % 2 == 0 ? .red : .blue,
                position: Position3D(x: Float(i), y: 0, z: 0)
            )
        }
        
        for player in players {
            gameState.addPlayer(player)
        }
        
        gameState.startGame()
        
        // 大量の状態更新
        let updateCount = 500
        let startTime = Date()
        
        for i in 0..<updateCount {
            // プレイヤー位置更新
            let playerIndex = i % players.count
            let updatedPlayer = Player(
                id: players[playerIndex].id,
                name: players[playerIndex].name,
                color: players[playerIndex].color,
                position: Position3D(
                    x: Float.random(in: -5...5),
                    y: 0,
                    z: Float.random(in: -5...5)
                ),
                isActive: players[playerIndex].isActive,
                score: players[playerIndex].score,
                createdAt: players[playerIndex].createdAt
            )
            
            gameState.updatePlayer(updatedPlayer)
            
            // インクスポット追加
            if i % 5 == 0 {
                let inkSpot = InkSpot(
                    id: InkSpotId(),
                    position: Position3D(
                        x: Float.random(in: -5...5),
                        y: 0,
                        z: Float.random(in: -5...5)
                    ),
                    color: i % 2 == 0 ? .red : .blue,
                    size: 0.5,
                    ownerId: players[playerIndex].id
                )
                gameState.addInkSpot(inkSpot)
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // パフォーマンス要件: 500回の状態更新が1秒以内
        #expect(duration < 1.0)
        
        print("ゲーム状態更新パフォーマンス: \(updateCount)回の状態更新を\(String(format: "%.3f", duration))秒で完了")
    }
    
    // MARK: - Memory Performance Tests
    
    @Test("メモリ使用量テスト")
    func testMemoryUsage() async throws {
        let gameState = GameState()
        gameState.initializeGame()
        
        // 初期メモリ使用量測定
        let initialMemory = getMemoryUsage()
        
        // 大量のデータ生成
        let players = (0..<100).map { i in
            Player(
                id: PlayerId(),
                name: "Player\(i)",
                color: i % 2 == 0 ? .red : .blue,
                position: Position3D(x: Float(i), y: 0, z: 0)
            )
        }
        
        for player in players {
            gameState.addPlayer(player)
        }
        
        // 大量のインクスポット生成
        for i in 0..<5000 {
            let inkSpot = InkSpot(
                id: InkSpotId(),
                position: Position3D(
                    x: Float.random(in: -50...50),
                    y: 0,
                    z: Float.random(in: -50...50)
                ),
                color: i % 2 == 0 ? .red : .blue,
                size: Float.random(in: 0.1...1.0),
                ownerId: players[i % players.count].id
            )
            gameState.addInkSpot(inkSpot)
        }
        
        // 最大メモリ使用量測定
        let maxMemory = getMemoryUsage()
        let memoryIncrease = maxMemory - initialMemory
        
        // データクリア
        gameState.clearGame()
        
        // クリア後のメモリ使用量測定
        let finalMemory = getMemoryUsage()
        let memoryRecovered = maxMemory - finalMemory
        
        // メモリ要件: 5000個のインクスポットで100MB以下の増加
        #expect(memoryIncrease < 100 * 1024 * 1024) // 100MB
        
        // メモリリーク要件: クリア後に80%以上のメモリが回収される
        #expect(memoryRecovered > memoryIncrease * 0.8)
        
        print("メモリ使用量: 初期=\(formatBytes(initialMemory)), 最大=\(formatBytes(maxMemory)), 最終=\(formatBytes(finalMemory))")
        print("メモリ増加: \(formatBytes(memoryIncrease)), 回収: \(formatBytes(memoryRecovered))")
    }
    
    // MARK: - Concurrent Performance Tests
    
    @Test("並行処理パフォーマンステスト")
    func testConcurrentPerformance() async throws {
        let gameState = GameState()
        gameState.initializeGame()
        
        let player1 = Player(id: PlayerId(), name: "Player1", color: .red, position: Position3D(x: 0, y: 0, z: 0))
        let player2 = Player(id: PlayerId(), name: "Player2", color: .blue, position: Position3D(x: 5, y: 0, z: 5))
        
        gameState.addPlayer(player1)
        gameState.addPlayer(player2)
        gameState.startGame()
        
        let startTime = Date()
        
        // 並行してインクスポットを追加
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let inkSpot = InkSpot(
                        id: InkSpotId(),
                        position: Position3D(
                            x: Float.random(in: -10...10),
                            y: 0,
                            z: Float.random(in: -10...10)
                        ),
                        color: i % 2 == 0 ? .red : .blue,
                        size: 0.5,
                        ownerId: i % 2 == 0 ? player1.id : player2.id
                    )
                    gameState.addInkSpot(inkSpot)
                }
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // パフォーマンス要件: 100個の並行インクスポット追加が0.5秒以内
        #expect(duration < 0.5)
        #expect(gameState.inkSpots.count == 100)
        
        print("並行処理パフォーマンス: 100個のインクスポットの並行追加を\(String(format: "%.3f", duration))秒で完了")
    }
}

// MARK: - Helper Functions

private func getMemoryUsage() -> UInt64 {
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
        return info.resident_size
    } else {
        return 0
    }
}

private func formatBytes(_ bytes: UInt64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useKB, .useBytes]
    formatter.countStyle = .memory
    return formatter.string(fromByteCount: Int64(bytes))
}

// MARK: - Extensions for Testing

extension GameState {
    func clearGame() {
        players.removeAll()
        inkSpots.removeAll()
        currentPhase = .waiting
        isGameActive = false
    }
}
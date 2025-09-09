//
//  EdgeCaseTests.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import Testing
import XCTest
@testable import ARSplatoonGame
import Domain
import Application
import Infrastructure

/// エッジケースのテストクラス
final class EdgeCaseTests: XCTestCase {
    
    var gameState: GameState!
    
    override func setUp() {
        super.setUp()
        gameState = GameState()
    }
    
    override func tearDown() {
        gameState = nil
        super.tearDown()
    }
    
    // MARK: - ゲームバランス設定のエッジケース
    
    func testGameBalanceSettingsExtremeValues() {
        let settings = gameState.balanceSettings
        
        // 極端に小さい値
        settings.inkShotCooldown = 0.01
        settings.inkMaxRange = 0.1
        settings.inkSpotBaseSize = 0.01
        settings.playerStunDuration = 0.1
        
        XCTAssertTrue(settings.isValid, "極端に小さい値でも有効であるべき")
        
        // 極端に大きい値
        settings.inkShotCooldown = 10.0
        settings.inkMaxRange = 100.0
        settings.inkSpotBaseSize = 5.0
        settings.playerStunDuration = 30.0
        
        XCTAssertTrue(settings.isValid, "極端に大きい値でも有効であるべき")
        
        // 無効な値
        settings.inkShotCooldown = -1.0
        XCTAssertFalse(settings.isValid, "負の値は無効であるべき")
        
        settings.inkShotCooldown = 0.3 // 有効な値に戻す
        settings.inkSpotBaseSize = 0.0
        XCTAssertFalse(settings.isValid, "ゼロサイズは無効であるべき")
    }
    
    func testGameBalanceSettingsDifficultyTransitions() {
        let settings = gameState.balanceSettings
        
        // 難易度変更のテスト
        let originalCooldown = settings.inkShotCooldown
        
        settings.difficultyLevel = .easy
        let easyCooldown = settings.inkShotCooldown
        
        settings.difficultyLevel = .hard
        let hardCooldown = settings.inkShotCooldown
        
        XCTAssertLessThan(easyCooldown, hardCooldown, "イージーはハードより発射間隔が短いべき")
        
        // 設定の保存と読み込み
        settings.saveSettings()
        let newSettings = GameBalanceSettings()
        
        XCTAssertEqual(newSettings.difficultyLevel, .hard, "設定が正しく保存・読み込みされるべき")
    }
    
    // MARK: - フィードバック管理のエッジケース
    
    func testFeedbackManagerWithNoData() {
        let feedbackManager = gameState.feedbackManager
        
        // データなしでの分析
        feedbackManager.updateAnalysis()
        XCTAssertNil(feedbackManager.currentAnalysis, "データなしでは分析結果はnilであるべき")
        
        // 推奨設定の取得
        let recommendedSettings = feedbackManager.getRecommendedBalanceSettings()
        XCTAssertNil(recommendedSettings, "データ不足では推奨設定はnilであるべき")
        
        // 改善提案の取得
        let suggestions = feedbackManager.getImprovementSuggestions()
        XCTAssertTrue(suggestions.isEmpty, "データなしでは改善提案は空であるべき")
    }
    
    func testFeedbackManagerWithExtremeRatings() {
        let feedbackManager = gameState.feedbackManager
        
        // 極端に低い評価のフィードバック
        let lowRatingFeedback = GameFeedbackManager.GameSessionFeedback(
            sessionId: UUID(),
            gameDuration: 180,
            playerCount: 2,
            difficultyLevel: "ノーマル",
            inkShotCooldownRating: 1,
            inkRangeRating: 1,
            stunDurationRating: 1,
            gameTimeRating: 1,
            overallBalanceRating: 1,
            funRating: 1,
            difficultyRating: 1,
            fairnessRating: 1,
            replayabilityRating: 1,
            comments: "すべてが悪い",
            suggestedImprovements: "全面的な見直しが必要",
            finalScore: 0.0,
            inkSpotsPlaced: 0,
            timesStunned: 100,
            averageInkSpotSize: 0.1
        )
        
        // 複数の低評価フィードバックを追加
        for _ in 0..<10 {
            feedbackManager.collectFeedback(lowRatingFeedback)
        }
        
        feedbackManager.updateAnalysis()
        
        guard let analysis = feedbackManager.currentAnalysis else {
            XCTFail("分析結果が生成されるべき")
            return
        }
        
        XCTAssertFalse(analysis.commonComplaints.isEmpty, "低評価では不満が特定されるべき")
        XCTAssertLessThan(analysis.playerRetention, 0.5, "低評価では継続率が低いべき")
        
        // 極端に高い評価のフィードバック
        let highRatingFeedback = GameFeedbackManager.GameSessionFeedback(
            sessionId: UUID(),
            gameDuration: 180,
            playerCount: 2,
            difficultyLevel: "ノーマル",
            inkShotCooldownRating: 5,
            inkRangeRating: 5,
            stunDurationRating: 5,
            gameTimeRating: 5,
            overallBalanceRating: 5,
            funRating: 5,
            difficultyRating: 3, // 適切な難易度
            fairnessRating: 5,
            replayabilityRating: 5,
            comments: "完璧なゲーム",
            suggestedImprovements: "改善点なし",
            finalScore: 100.0,
            inkSpotsPlaced: 150,
            timesStunned: 0,
            averageInkSpotSize: 0.5
        )
        
        // 高評価フィードバックで上書き
        feedbackManager.clearAllFeedbacks()
        for _ in 0..<10 {
            feedbackManager.collectFeedback(highRatingFeedback)
        }
        
        feedbackManager.updateAnalysis()
        
        guard let highAnalysis = feedbackManager.currentAnalysis else {
            XCTFail("分析結果が生成されるべき")
            return
        }
        
        XCTAssertTrue(highAnalysis.commonComplaints.isEmpty, "高評価では不満は少ないべき")
        XCTAssertGreaterThan(highAnalysis.playerRetention, 0.8, "高評価では継続率が高いべき")
    }
    
    // MARK: - ゲーム状態のエッジケース
    
    func testGameStateWithRapidStateChanges() async {
        // 高速な状態変更のテスト
        let player1 = Player(
            id: PlayerId(),
            name: "Player1",
            color: PlayerColor.red,
            position: Position3D(x: 0, y: 0, z: 0)
        )
        let player2 = Player(
            id: PlayerId(),
            name: "Player2",
            color: PlayerColor.blue,
            position: Position3D(x: 1, y: 0, z: 1)
        )
        
        // 連続したゲーム開始・終了
        for _ in 0..<5 {
            await gameState.startGame(with: [player1, player2])
            
            // 短時間待機
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            
            await gameState.endGame()
            await gameState.resetGame()
        }
        
        // 最終状態の確認
        XCTAssertEqual(gameState.currentPhase, .waiting, "最終的に待機状態であるべき")
        XCTAssertFalse(gameState.isGameActive, "ゲームは非アクティブであるべき")
    }
    
    func testGameStateWithExtremeInkShooting() async {
        let player1 = Player(
            id: PlayerId(),
            name: "Player1",
            color: PlayerColor.red,
            position: Position3D(x: 0, y: 0, z: 0)
        )
        let player2 = Player(
            id: PlayerId(),
            name: "Player2",
            color: PlayerColor.blue,
            position: Position3D(x: 1, y: 0, z: 1)
        )
        
        await gameState.startGame(with: [player1, player2])
        
        // 極端に多数のインク発射
        let positions = [
            Position3D(x: 0.1, y: 0, z: 0.1),
            Position3D(x: 0.2, y: 0, z: 0.2),
            Position3D(x: 0.3, y: 0, z: 0.3),
            Position3D(x: 0.4, y: 0, z: 0.4),
            Position3D(x: 0.5, y: 0, z: 0.5)
        ]
        
        // 連続発射
        for position in positions {
            await gameState.shootInk(playerId: player1.id, at: position)
        }
        
        // 極端に小さいサイズ
        await gameState.shootInk(playerId: player1.id, at: Position3D(x: 0.6, y: 0, z: 0.6), size: 0.01)
        
        // 極端に大きいサイズ
        await gameState.shootInk(playerId: player1.id, at: Position3D(x: 0.7, y: 0, z: 0.7), size: 10.0)
        
        // ゲーム状態の確認
        XCTAssertEqual(gameState.currentPhase, .playing, "ゲームは継続中であるべき")
    }
    
    // MARK: - メモリとパフォーマンスのエッジケース
    
    func testMemoryUsageWithLargeDataSets() {
        let feedbackManager = gameState.feedbackManager
        
        // 大量のフィードバックデータを生成
        for i in 0..<1000 {
            let feedback = GameFeedbackManager.GameSessionFeedback(
                sessionId: UUID(),
                gameDuration: Double(120 + i % 180),
                playerCount: 2 + i % 3,
                difficultyLevel: ["イージー", "ノーマル", "ハード"][i % 3],
                inkShotCooldownRating: 1 + i % 5,
                inkRangeRating: 1 + i % 5,
                stunDurationRating: 1 + i % 5,
                gameTimeRating: 1 + i % 5,
                overallBalanceRating: 1 + i % 5,
                funRating: 1 + i % 5,
                difficultyRating: 1 + i % 5,
                fairnessRating: 1 + i % 5,
                replayabilityRating: 1 + i % 5,
                comments: "テストコメント \(i)",
                suggestedImprovements: "テスト改善提案 \(i)",
                finalScore: Float(i % 100),
                inkSpotsPlaced: i % 200,
                timesStunned: i % 10,
                averageInkSpotSize: 0.1 + Float(i % 10) * 0.05
            )
            
            feedbackManager.collectFeedback(feedback)
        }
        
        // 分析実行
        feedbackManager.updateAnalysis()
        
        XCTAssertNotNil(feedbackManager.currentAnalysis, "大量データでも分析が実行されるべき")
        XCTAssertEqual(feedbackManager.feedbacks.count, 1000, "すべてのフィードバックが保存されるべき")
        
        // CSVエクスポートのテスト
        let csvData = feedbackManager.exportFeedbacksAsCSV()
        XCTAssertFalse(csvData.isEmpty, "CSVデータが生成されるべき")
        XCTAssertTrue(csvData.contains("Date,SessionId"), "CSVヘッダーが含まれるべき")
    }
    
    func testConcurrentOperations() async {
        let player1 = Player(
            id: PlayerId(),
            name: "Player1",
            color: PlayerColor.red,
            position: Position3D(x: 0, y: 0, z: 0)
        )
        let player2 = Player(
            id: PlayerId(),
            name: "Player2",
            color: PlayerColor.blue,
            position: Position3D(x: 1, y: 0, z: 1)
        )
        
        await gameState.startGame(with: [player1, player2])
        
        // 並行操作のテスト
        await withTaskGroup(of: Void.self) { group in
            // 複数のインク発射を並行実行
            for i in 0..<10 {
                group.addTask {
                    let position = Position3D(
                        x: Float(i) * 0.1,
                        y: 0,
                        z: Float(i) * 0.1
                    )
                    await self.gameState.shootInk(playerId: player1.id, at: position)
                }
            }
            
            // 設定変更を並行実行
            group.addTask {
                self.gameState.balanceSettings.inkShotCooldown = 0.5
                self.gameState.balanceSettings.saveSettings()
            }
            
            // フィードバック収集を並行実行
            group.addTask {
                let feedback = GameFeedbackManager.GameSessionFeedback(
                    sessionId: UUID(),
                    gameDuration: 180,
                    playerCount: 2,
                    difficultyLevel: "ノーマル",
                    inkShotCooldownRating: 3,
                    inkRangeRating: 3,
                    stunDurationRating: 3,
                    gameTimeRating: 3,
                    overallBalanceRating: 3,
                    funRating: 3,
                    difficultyRating: 3,
                    fairnessRating: 3,
                    replayabilityRating: 3,
                    comments: "並行テスト",
                    suggestedImprovements: "なし",
                    finalScore: 50.0,
                    inkSpotsPlaced: 50,
                    timesStunned: 2,
                    averageInkSpotSize: 0.4
                )
                self.gameState.feedbackManager.collectFeedback(feedback)
            }
        }
        
        // 並行操作後の状態確認
        XCTAssertEqual(gameState.currentPhase, .playing, "並行操作後もゲームは継続中であるべき")
        XCTAssertFalse(gameState.feedbackManager.feedbacks.isEmpty, "フィードバックが収集されているべき")
    }
    
    // MARK: - 境界値テスト
    
    func testBoundaryValues() {
        let settings = gameState.balanceSettings
        
        // 時間の境界値
        settings.gameDuration = 1.0 // 最小値近く
        XCTAssertTrue(settings.isValid, "最小時間でも有効であるべき")
        
        settings.gameDuration = 3600.0 // 1時間
        XCTAssertTrue(settings.isValid, "長時間でも有効であるべき")
        
        // サイズの境界値
        settings.inkSpotBaseSize = 0.001
        settings.inkSpotMaxSize = 0.002
        XCTAssertTrue(settings.isValid, "極小サイズでも有効であるべき")
        
        settings.inkSpotBaseSize = 5.0
        settings.inkSpotMaxSize = 10.0
        XCTAssertTrue(settings.isValid, "大サイズでも有効であるべき")
        
        // 無効な境界値
        settings.inkSpotBaseSize = 1.0
        settings.inkSpotMaxSize = 0.5 // baseより小さい
        XCTAssertFalse(settings.isValid, "maxがbaseより小さい場合は無効であるべき")
    }
    
    // MARK: - エラー処理のエッジケース
    
    func testErrorHandlingWithCorruptedData() {
        // 破損したUserDefaultsデータのシミュレーション
        UserDefaults.standard.set("invalid_data", forKey: "gameFeedbacks")
        
        // 新しいフィードバックマネージャーを作成（破損データの読み込みを試行）
        let feedbackManager = GameFeedbackManager()
        
        // 破損データでも正常に初期化されるべき
        XCTAssertTrue(feedbackManager.feedbacks.isEmpty, "破損データでは空の配列で初期化されるべき")
        
        // 正常なフィードバックを追加できるべき
        let feedback = GameFeedbackManager.GameSessionFeedback(
            sessionId: UUID(),
            gameDuration: 180,
            playerCount: 2,
            difficultyLevel: "ノーマル",
            inkShotCooldownRating: 3,
            inkRangeRating: 3,
            stunDurationRating: 3,
            gameTimeRating: 3,
            overallBalanceRating: 3,
            funRating: 3,
            difficultyRating: 3,
            fairnessRating: 3,
            replayabilityRating: 3,
            comments: "復旧テスト",
            suggestedImprovements: "なし",
            finalScore: 50.0,
            inkSpotsPlaced: 50,
            timesStunned: 2,
            averageInkSpotSize: 0.4
        )
        
        feedbackManager.collectFeedback(feedback)
        XCTAssertEqual(feedbackManager.feedbacks.count, 1, "復旧後は正常にフィードバックが追加されるべき")
        
        // クリーンアップ
        UserDefaults.standard.removeObject(forKey: "gameFeedbacks")
    }
}
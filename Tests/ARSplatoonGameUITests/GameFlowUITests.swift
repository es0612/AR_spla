//
//  GameFlowUITests.swift
//  ARSplatoonGameUITests
//
//  Created by Kiro on 2025-01-09.
//

import XCTest

/// UI tests for complete game flow
final class GameFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Menu Navigation Tests
    
    func testMenuNavigation() throws {
        // メインメニューの表示確認
        let menuTitle = app.staticTexts["ARスプラトゥーン"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 5))
        
        // シングルプレイヤーボタンの確認
        let singlePlayerButton = app.buttons["シングルプレイヤー"]
        XCTAssertTrue(singlePlayerButton.exists)
        
        // マルチプレイヤーボタンの確認
        let multiplayerButton = app.buttons["マルチプレイヤー"]
        XCTAssertTrue(multiplayerButton.exists)
        
        // 設定ボタンの確認
        let settingsButton = app.buttons["設定"]
        XCTAssertTrue(settingsButton.exists)
        
        // チュートリアルボタンの確認
        let tutorialButton = app.buttons["チュートリアル"]
        XCTAssertTrue(tutorialButton.exists)
    }
    
    func testSettingsNavigation() throws {
        // 設定画面への遷移
        let settingsButton = app.buttons["設定"]
        settingsButton.tap()
        
        // 設定画面の表示確認
        let settingsTitle = app.staticTexts["設定"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
        
        // 設定項目の確認
        let hapticToggle = app.switches["触覚フィードバック"]
        XCTAssertTrue(hapticToggle.exists)
        
        let soundToggle = app.switches["サウンド"]
        XCTAssertTrue(soundToggle.exists)
        
        // 戻るボタンの確認
        let backButton = app.buttons["戻る"]
        XCTAssertTrue(backButton.exists)
        
        // メインメニューに戻る
        backButton.tap()
        
        let menuTitle = app.staticTexts["ARスプラトゥーン"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 3))
    }
    
    func testTutorialNavigation() throws {
        // チュートリアル画面への遷移
        let tutorialButton = app.buttons["チュートリアル"]
        tutorialButton.tap()
        
        // チュートリアル画面の表示確認
        let tutorialTitle = app.staticTexts["チュートリアル"]
        XCTAssertTrue(tutorialTitle.waitForExistence(timeout: 3))
        
        // チュートリアル内容の確認
        let step1 = app.staticTexts["1. デバイスを動かして平面を検出"]
        XCTAssertTrue(step1.exists)
        
        let step2 = app.staticTexts["2. ゲームフィールドをタップして配置"]
        XCTAssertTrue(step2.exists)
        
        let step3 = app.staticTexts["3. 画面をタップしてインクを発射"]
        XCTAssertTrue(step3.exists)
        
        // 完了ボタンの確認
        let completeButton = app.buttons["完了"]
        XCTAssertTrue(completeButton.exists)
        
        // メインメニューに戻る
        completeButton.tap()
        
        let menuTitle = app.staticTexts["ARスプラトゥーン"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 3))
    }
    
    // MARK: - Game Flow Tests
    
    func testSinglePlayerGameFlow() throws {
        // シングルプレイヤーゲーム開始
        let singlePlayerButton = app.buttons["シングルプレイヤー"]
        singlePlayerButton.tap()
        
        // AR画面の表示確認
        let arView = app.otherElements["ARGameView"]
        XCTAssertTrue(arView.waitForExistence(timeout: 5))
        
        // 平面検出メッセージの確認
        let scanMessage = app.staticTexts["平面をスキャンしています..."]
        XCTAssertTrue(scanMessage.waitForExistence(timeout: 3))
        
        // ゲームUI要素の確認
        let scoreLabel = app.staticTexts["スコア: 0"]
        XCTAssertTrue(scoreLabel.waitForExistence(timeout: 5))
        
        let timerLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '残り時間:'")).firstMatch
        XCTAssertTrue(timerLabel.waitForExistence(timeout: 5))
        
        // 一時停止ボタンの確認
        let pauseButton = app.buttons["一時停止"]
        XCTAssertTrue(pauseButton.exists)
        
        // 一時停止メニューのテスト
        pauseButton.tap()
        
        let pauseMenu = app.otherElements["PauseMenu"]
        XCTAssertTrue(pauseMenu.waitForExistence(timeout: 3))
        
        let resumeButton = app.buttons["再開"]
        XCTAssertTrue(resumeButton.exists)
        
        let quitButton = app.buttons["終了"]
        XCTAssertTrue(quitButton.exists)
        
        // ゲーム終了
        quitButton.tap()
        
        // メインメニューに戻ることを確認
        let menuTitle = app.staticTexts["ARスプラトゥーン"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 5))
    }
    
    func testMultiplayerConnectionFlow() throws {
        // マルチプレイヤーゲーム開始
        let multiplayerButton = app.buttons["マルチプレイヤー"]
        multiplayerButton.tap()
        
        // 接続画面の表示確認
        let connectionView = app.otherElements["MultiplayerConnectionView"]
        XCTAssertTrue(connectionView.waitForExistence(timeout: 5))
        
        // 接続状態の確認
        let statusLabel = app.staticTexts["他のプレイヤーを検索中..."]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 3))
        
        // ホストボタンの確認
        let hostButton = app.buttons["ホストとして開始"]
        XCTAssertTrue(hostButton.exists)
        
        // 参加ボタンの確認
        let joinButton = app.buttons["ゲームに参加"]
        XCTAssertTrue(joinButton.exists)
        
        // キャンセルボタンの確認
        let cancelButton = app.buttons["キャンセル"]
        XCTAssertTrue(cancelButton.exists)
        
        // メインメニューに戻る
        cancelButton.tap()
        
        let menuTitle = app.staticTexts["ARスプラトゥーン"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 3))
    }
    
    // MARK: - Error Handling Tests
    
    func testARErrorHandling() throws {
        // ARサポートなしデバイスでのエラーハンドリング（シミュレーター）
        let singlePlayerButton = app.buttons["シングルプレイヤー"]
        singlePlayerButton.tap()
        
        // エラーメッセージの確認（シミュレーターではARが利用できない）
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 10) {
            let errorMessage = errorAlert.staticTexts.firstMatch
            XCTAssertTrue(errorMessage.exists)
            
            // OKボタンでエラーを閉じる
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // メインメニューに戻ることを確認
        let menuTitle = app.staticTexts["ARスプラトゥーン"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 5))
    }
    
    func testNetworkErrorHandling() throws {
        // ネットワークエラーのテスト
        let multiplayerButton = app.buttons["マルチプレイヤー"]
        multiplayerButton.tap()
        
        let hostButton = app.buttons["ホストとして開始"]
        hostButton.tap()
        
        // 接続タイムアウトまたはエラーの確認
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 15) {
            let errorMessage = errorAlert.staticTexts.firstMatch
            XCTAssertTrue(errorMessage.exists)
            
            // OKボタンでエラーを閉じる
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // 接続画面に戻るかメインメニューに戻ることを確認
        let connectionView = app.otherElements["MultiplayerConnectionView"]
        let menuTitle = app.staticTexts["ARスプラトゥーン"]
        
        XCTAssertTrue(connectionView.exists || menuTitle.exists)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibility() throws {
        // アクセシビリティ要素の確認
        let menuTitle = app.staticTexts["ARスプラトゥーン"]
        XCTAssertTrue(menuTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(menuTitle.isAccessibilityElement)
        
        let singlePlayerButton = app.buttons["シングルプレイヤー"]
        XCTAssertTrue(singlePlayerButton.isAccessibilityElement)
        XCTAssertEqual(singlePlayerButton.accessibilityTraits, .button)
        
        let multiplayerButton = app.buttons["マルチプレイヤー"]
        XCTAssertTrue(multiplayerButton.isAccessibilityElement)
        XCTAssertEqual(multiplayerButton.accessibilityTraits, .button)
        
        let settingsButton = app.buttons["設定"]
        XCTAssertTrue(settingsButton.isAccessibilityElement)
        XCTAssertEqual(settingsButton.accessibilityTraits, .button)
        
        let tutorialButton = app.buttons["チュートリアル"]
        XCTAssertTrue(tutorialButton.isAccessibilityElement)
        XCTAssertEqual(tutorialButton.accessibilityTraits, .button)
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        // アプリ起動パフォーマンステスト
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testMenuNavigationPerformance() throws {
        // メニューナビゲーションパフォーマンステスト
        measure(metrics: [XCTClockMetric()]) {
            let settingsButton = app.buttons["設定"]
            settingsButton.tap()
            
            let backButton = app.buttons["戻る"]
            backButton.tap()
            
            let tutorialButton = app.buttons["チュートリアル"]
            tutorialButton.tap()
            
            let completeButton = app.buttons["完了"]
            completeButton.tap()
        }
    }
    
    // MARK: - Stress Tests
    
    func testRepeatedNavigation() throws {
        // 繰り返しナビゲーションテスト
        for _ in 0..<10 {
            let settingsButton = app.buttons["設定"]
            settingsButton.tap()
            
            let settingsTitle = app.staticTexts["設定"]
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
            
            let backButton = app.buttons["戻る"]
            backButton.tap()
            
            let menuTitle = app.staticTexts["ARスプラトゥーン"]
            XCTAssertTrue(menuTitle.waitForExistence(timeout: 3))
        }
    }
    
    func testMemoryStability() throws {
        // メモリ安定性テスト
        for _ in 0..<5 {
            let singlePlayerButton = app.buttons["シングルプレイヤー"]
            singlePlayerButton.tap()
            
            // AR画面が表示されるまで待機
            let arView = app.otherElements["ARGameView"]
            if arView.waitForExistence(timeout: 5) {
                // 一時停止して終了
                let pauseButton = app.buttons["一時停止"]
                if pauseButton.exists {
                    pauseButton.tap()
                    
                    let quitButton = app.buttons["終了"]
                    if quitButton.exists {
                        quitButton.tap()
                    }
                }
            } else {
                // エラーが発生した場合はアラートを閉じる
                let errorAlert = app.alerts.firstMatch
                if errorAlert.exists {
                    let okButton = errorAlert.buttons["OK"]
                    if okButton.exists {
                        okButton.tap()
                    }
                }
            }
            
            // メインメニューに戻ることを確認
            let menuTitle = app.staticTexts["ARスプラトゥーン"]
            XCTAssertTrue(menuTitle.waitForExistence(timeout: 5))
        }
    }
}
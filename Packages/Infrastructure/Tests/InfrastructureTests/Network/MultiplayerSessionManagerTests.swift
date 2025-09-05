//
//  MultiplayerSessionManagerTests.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

@testable import Domain
import Foundation
@testable import Infrastructure
import MultipeerConnectivity
import Testing
@testable import TestSupport

struct MultiplayerSessionManagerTests {
    @Test("セッションマネージャーの初期化")
    func testInitialization() {
        let (sessionManager, _, _) = createSessionManager()

        #expect(sessionManager.currentSession == nil)
        #expect(sessionManager.sessionState == .idle)
        #expect(sessionManager.connectedPlayers.isEmpty)
        #expect(sessionManager.sessionErrors.isEmpty)
    }

    @Test("新しいセッションの開始")
    func testStartSession() throws {
        let (sessionManager, _, _) = createSessionManager()

        let players = [
            PlayerBuilder()
                .withId(PlayerId())
                .withName("Player1")
                .withColor(PlayerColor.red)
                .build(),
            PlayerBuilder()
                .withId(PlayerId())
                .withName("Player2")
                .withColor(PlayerColor.blue)
                .build()
        ]

        try sessionManager.startSession(with: players, duration: 180.0)

        #expect(sessionManager.sessionState == .waiting)
        #expect(sessionManager.connectedPlayers.count == 2)
    }

    @Test("空のプレイヤーリストでセッション開始時のエラー")
    func testStartSessionWithEmptyPlayers() {
        let (sessionManager, _, _) = createSessionManager()

        #expect(throws: SessionError.self) {
            try sessionManager.startSession(with: [], duration: 180.0)
        }
    }

    @Test("既にアクティブなセッションがある場合のエラー")
    func testStartSessionWhenAlreadyActive() throws {
        let (sessionManager, _, _) = createSessionManager()

        let players = [
            PlayerBuilder()
                .withId(PlayerId())
                .withName("Player1")
                .withColor(PlayerColor.red)
                .build()
        ]

        try sessionManager.startSession(with: players, duration: 180.0)

        #expect(throws: SessionError.self) {
            try sessionManager.startSession(with: players, duration: 180.0)
        }
    }

    @Test("セッション情報の取得")
    func testGetSessionInfo() throws {
        let (sessionManager, _, _) = createSessionManager()

        // セッションがない場合
        #expect(sessionManager.getSessionInfo() == nil)

        // セッションを開始
        let players = [
            PlayerBuilder()
                .withId(PlayerId())
                .withName("Player1")
                .withColor(PlayerColor.red)
                .build(),
            PlayerBuilder()
                .withId(PlayerId())
                .withName("Player2")
                .withColor(PlayerColor.blue)
                .build()
        ]

        try sessionManager.startSession(with: players, duration: 180.0)

        // セッション情報を取得
        let sessionInfo = sessionManager.getSessionInfo()
        #expect(sessionInfo != nil)
        #expect(sessionInfo?.playerCount == 2)
    }

    @Test("ゲーム開始準備の確認")
    func testIsReadyToStart() throws {
        let (sessionManager, _, _) = createSessionManager()

        // 初期状態では準備できていない
        #expect(!sessionManager.isReadyToStart())

        // 1人のプレイヤーでは不十分
        let onePlayer = [
            PlayerBuilder()
                .withId(PlayerId())
                .withName("Player1")
                .withColor(PlayerColor.red)
                .build()
        ]

        try sessionManager.startSession(with: onePlayer, duration: 180.0)
        #expect(!sessionManager.isReadyToStart())
    }

    @Test("セッション統計の取得")
    func testGetSessionStats() throws {
        let (sessionManager, _, _) = createSessionManager()

        let stats = sessionManager.getSessionStats()
        #expect(stats.currentState == .idle)
        #expect(stats.connectedPlayersCount == 0)
        #expect(stats.errorCount == 0)
        #expect(!stats.isGameActive)
    }

    @Test("セッション状態の変更")
    func testSessionStateChanges() throws {
        let (sessionManager, _, _) = createSessionManager()

        var stateChanges: [SessionState] = []
        sessionManager.onSessionStateChanged = { state in
            stateChanges.append(state)
        }

        let players = [
            PlayerBuilder()
                .withId(PlayerId())
                .withName("Player1")
                .withColor(PlayerColor.red)
                .build(),
            PlayerBuilder()
                .withId(PlayerId())
                .withName("Player2")
                .withColor(PlayerColor.blue)
                .build()
        ]

        try sessionManager.startSession(with: players, duration: 180.0)

        #expect(stateChanges.contains(.creating))
    }

    @Test("プレイヤー参加・離脱のコールバック")
    func testPlayerJoinLeaveCallbacks() throws {
        let (sessionManager, _, _) = createSessionManager()

        var joinedPlayers: [Player] = []
        var leftPlayers: [Player] = []

        sessionManager.onPlayerJoined = { player in
            joinedPlayers.append(player)
        }

        sessionManager.onPlayerLeft = { player in
            leftPlayers.append(player)
        }

        // 初期状態では空
        #expect(joinedPlayers.isEmpty)
        #expect(leftPlayers.isEmpty)
    }

    // MARK: - Helper Methods

    private func createSessionManager() -> (MultiplayerSessionManager, GameSynchronizationService, ConnectionRecoveryService) {
        let gameRepository = MultiPeerGameRepository(displayName: "TestPeer")
        let syncService = GameSynchronizationService(gameRepository: gameRepository)
        let recoveryService = ConnectionRecoveryService(gameRepository: gameRepository)

        let sessionManager = MultiplayerSessionManager(
            gameRepository: gameRepository,
            synchronizationService: syncService,
            recoveryService: recoveryService
        )

        return (sessionManager, syncService, recoveryService)
    }
}

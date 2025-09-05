//
//  MultiplayerSessionManager.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

import Application
import Domain
import Foundation
import MultipeerConnectivity

// MARK: - MultiplayerSessionManager

/// Manager for multiplayer game sessions
public class MultiplayerSessionManager {
    // MARK: - Properties

    private let gameRepository: MultiPeerGameRepository
    private let synchronizationService: GameSynchronizationService
    private let recoveryService: ConnectionRecoveryService

    // MARK: - Session State

    public private(set) var currentSession: GameSession?
    public private(set) var sessionState: SessionState = .idle
    public private(set) var connectedPlayers: [Player] = []
    public private(set) var sessionErrors: [SessionError] = []

    // MARK: - Callbacks

    public var onSessionStateChanged: ((SessionState) -> Void)?
    public var onPlayerJoined: ((Player) -> Void)?
    public var onPlayerLeft: ((Player) -> Void)?
    public var onSessionError: ((SessionError) -> Void)?

    // MARK: - Initialization

    public init(
        gameRepository: MultiPeerGameRepository,
        synchronizationService: GameSynchronizationService,
        recoveryService: ConnectionRecoveryService
    ) {
        self.gameRepository = gameRepository
        self.synchronizationService = synchronizationService
        self.recoveryService = recoveryService
    }

    // MARK: - Public API

    /// Start a new multiplayer session
    public func startSession(with players: [Player], duration: TimeInterval = 180.0) throws {
        guard sessionState == .idle else {
            throw SessionError.sessionAlreadyActive
        }

        guard !players.isEmpty else {
            throw SessionError.noPlayersProvided
        }

        sessionState = .creating
        onSessionStateChanged?(.creating)

        connectedPlayers = players

        // Only create GameSession if we have enough players
        if players.count >= 2 {
            let sessionId = GameSessionId()
            let gameSession = GameSession(
                id: sessionId,
                players: players,
                duration: duration
            )
            currentSession = gameSession
        }

        sessionState = .waiting
        onSessionStateChanged?(.waiting)
    }

    /// Get current session information
    public func getSessionInfo() -> SessionInfo? {
        guard let session = currentSession else { return nil }

        return SessionInfo(
            sessionId: session.id,
            state: sessionState,
            playerCount: connectedPlayers.count,
            gameStatus: session.status,
            remainingTime: session.remainingTime
        )
    }

    /// Check if session is ready to start game
    public func isReadyToStart() -> Bool {
        sessionState == .waiting && connectedPlayers.count >= 2
    }

    /// Get session statistics
    public func getSessionStats() -> SessionStats {
        SessionStats(
            currentState: sessionState,
            connectedPlayersCount: connectedPlayers.count,
            errorCount: sessionErrors.count,
            isGameActive: currentSession?.status == .active
        )
    }
}

// MARK: - SessionState

public enum SessionState: String, CaseIterable {
    case idle
    case creating
    case waiting
    case connecting
    case connected
    case reconnecting
    case leaving
    case ending
}

// MARK: - SessionError

public enum SessionError: Error, LocalizedError {
    case sessionAlreadyActive
    case noActiveSession
    case noPlayersProvided
    case sessionNotFound
    case gameAlreadyStarted
    case insufficientPlayers
    case connectionTimeout
    case sessionCreationFailed(Error)
    case joinSessionFailed(Error)
    case leaveSessionFailed(Error)
    case sessionEndFailed(Error)
    case gameStartFailed(Error)
    case synchronizationFailed(Error)
    case notificationFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .sessionAlreadyActive:
            return "セッションが既にアクティブです"
        case .noActiveSession:
            return "アクティブなセッションがありません"
        case .noPlayersProvided:
            return "プレイヤーが提供されていません"
        case .sessionNotFound:
            return "セッションが見つかりません"
        case .gameAlreadyStarted:
            return "ゲームは既に開始されています"
        case .insufficientPlayers:
            return "プレイヤーが不足しています"
        case .connectionTimeout:
            return "接続がタイムアウトしました"
        case let .sessionCreationFailed(error):
            return "セッション作成に失敗しました: \(error.localizedDescription)"
        case let .joinSessionFailed(error):
            return "セッション参加に失敗しました: \(error.localizedDescription)"
        case let .leaveSessionFailed(error):
            return "セッション離脱に失敗しました: \(error.localizedDescription)"
        case let .sessionEndFailed(error):
            return "セッション終了に失敗しました: \(error.localizedDescription)"
        case let .gameStartFailed(error):
            return "ゲーム開始に失敗しました: \(error.localizedDescription)"
        case let .synchronizationFailed(error):
            return "同期に失敗しました: \(error.localizedDescription)"
        case let .notificationFailed(error):
            return "通知に失敗しました: \(error.localizedDescription)"
        }
    }
}

// MARK: - SessionInfo

public struct SessionInfo {
    public let sessionId: GameSessionId
    public let state: SessionState
    public let playerCount: Int
    public let gameStatus: GameSessionStatus
    public let remainingTime: TimeInterval

    public init(
        sessionId: GameSessionId,
        state: SessionState,
        playerCount: Int,
        gameStatus: GameSessionStatus,
        remainingTime: TimeInterval
    ) {
        self.sessionId = sessionId
        self.state = state
        self.playerCount = playerCount
        self.gameStatus = gameStatus
        self.remainingTime = remainingTime
    }
}

// MARK: - SessionStats

public struct SessionStats {
    public let currentState: SessionState
    public let connectedPlayersCount: Int
    public let errorCount: Int
    public let isGameActive: Bool

    public init(
        currentState: SessionState,
        connectedPlayersCount: Int,
        errorCount: Int,
        isGameActive: Bool
    ) {
        self.currentState = currentState
        self.connectedPlayersCount = connectedPlayersCount
        self.errorCount = errorCount
        self.isGameActive = isGameActive
    }
}

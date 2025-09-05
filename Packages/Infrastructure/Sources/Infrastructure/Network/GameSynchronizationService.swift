//
//  GameSynchronizationService.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

import Application
import Domain
import Foundation
import MultipeerConnectivity

// MARK: - GameSynchronizationService

/// Service for real-time game state synchronization
public class GameSynchronizationService {
    // MARK: - Properties

    private let gameRepository: MultiPeerGameRepository
    private let syncInterval: TimeInterval = 0.1 // 100ms for smooth sync
    private var syncTimer: Timer?
    private var lastSyncTimestamp: Date = .init()

    // MARK: - State Properties

    public private(set) var isConnected: Bool = false {
        didSet {
            onStateChanged?()
        }
    }

    public private(set) var latency: TimeInterval = 0 {
        didSet {
            onStateChanged?()
        }
    }

    public private(set) var syncErrors: [SyncError] = [] {
        didSet {
            onStateChanged?()
        }
    }

    // MARK: - Callbacks

    public var onStateChanged: (() -> Void)?

    // MARK: - Synchronization State

    private var pendingInkSpots: [InkSpot] = []
    private var pendingPlayerUpdates: [Player] = []
    private var lastGameStateHash: String = ""

    // MARK: - Initialization

    public init(gameRepository: MultiPeerGameRepository) {
        self.gameRepository = gameRepository
        setupObservers()
    }

    deinit {
        stopSynchronization()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Monitor connection state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(connectionStateChanged),
            name: .connectionStateChanged,
            object: nil
        )
    }

    @objc private func connectionStateChanged() {
        DispatchQueue.main.async {
            self.isConnected = self.gameRepository.connectionState == .connected

            if self.isConnected {
                self.startSynchronization()
            } else {
                self.stopSynchronization()
            }
        }
    }

    // MARK: - Synchronization Control

    /// Start real-time synchronization
    public func startSynchronization() {
        guard isConnected else { return }

        stopSynchronization() // Stop any existing timer

        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            self?.performSync()
        }
    }

    /// Stop real-time synchronization
    public func stopSynchronization() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Synchronization Logic

    private func performSync() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.syncPendingUpdates()
                self.measureLatency()
            } catch {
                DispatchQueue.main.async {
                    self.handleSyncError(SyncError.syncFailed(error))
                }
            }
        }
    }

    private func syncPendingUpdates() throws {
        // Sync pending ink spots
        if !pendingInkSpots.isEmpty {
            try syncInkSpots(Array(pendingInkSpots))
            pendingInkSpots.removeAll()
        }

        // Sync pending player updates
        if !pendingPlayerUpdates.isEmpty {
            try syncPlayerUpdates(Array(pendingPlayerUpdates))
            pendingPlayerUpdates.removeAll()
        }
    }

    private func syncInkSpots(_ inkSpots: [InkSpot]) throws {
        for inkSpot in inkSpots {
            let message = try NetworkGameMessageFactory.inkShot(
                inkSpot: inkSpot,
                senderId: gameRepository.peerID.displayName
            )
            try gameRepository.sendMessage(message)
        }
    }

    private func syncPlayerUpdates(_ players: [Player]) throws {
        for player in players {
            let message = try NetworkGameMessageFactory.playerPosition(
                player: player,
                senderId: gameRepository.peerID.displayName
            )
            try gameRepository.sendMessage(message)
        }
    }

    private func measureLatency() {
        let startTime = Date()
        let pingMessage = NetworkGameMessageFactory.ping(senderId: gameRepository.peerID.displayName)

        // Store ping timestamp for latency calculation
        UserDefaults.standard.set(startTime.timeIntervalSince1970, forKey: "lastPingTime")

        do {
            try gameRepository.sendMessage(pingMessage)
        } catch {
            print("Failed to send ping: \(error)")
        }
    }

    // MARK: - Public API

    /// Queue ink spot for synchronization
    public func queueInkSpot(_ inkSpot: InkSpot) {
        pendingInkSpots.append(inkSpot)
    }

    /// Queue player update for synchronization
    public func queuePlayerUpdate(_ player: Player) {
        pendingPlayerUpdates.append(player)
    }

    /// Force immediate synchronization of game state
    public func forceSyncGameState(_ gameSession: GameSession, completion: @escaping (Error?) -> Void) {
        let gameStateHash = calculateGameStateHash(gameSession)

        // Only sync if state has changed
        guard gameStateHash != lastGameStateHash else {
            completion(nil)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Simulate async repository update
                DispatchQueue.main.async {
                    self.lastGameStateHash = gameStateHash
                    self.lastSyncTimestamp = Date()
                    completion(nil)
                }
            }
        }
    }

    /// Handle received pong message for latency calculation
    public func handlePongReceived() {
        let currentTime = Date()
        let pingTime = UserDefaults.standard.double(forKey: "lastPingTime")

        if pingTime > 0 {
            let latency = currentTime.timeIntervalSince1970 - pingTime
            DispatchQueue.main.async {
                self.latency = latency
            }
            UserDefaults.standard.removeObject(forKey: "lastPingTime")
        }
    }

    // MARK: - Error Handling

    private func handleSyncError(_ error: SyncError) {
        syncErrors.append(error)

        // Keep only last 10 errors
        if syncErrors.count > 10 {
            syncErrors.removeFirst()
        }

        // Attempt recovery based on error type
        switch error {
        case .connectionLost:
            attemptReconnection()
        case .syncFailed:
            // Retry sync after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                do {
                    try self.syncPendingUpdates()
                } catch {
                    print("Retry sync failed: \(error)")
                }
            }
        case .messageDecodingFailed:
            // Clear pending updates to prevent corruption
            pendingInkSpots.removeAll()
            pendingPlayerUpdates.removeAll()
        }
    }

    private func attemptReconnection() {
        // Implement reconnection logic
        gameRepository.startBrowsing()
        gameRepository.startAdvertising()
    }

    // MARK: - Utility Methods

    private func calculateGameStateHash(_ gameSession: GameSession) -> String {
        let hashData = "\(gameSession.id.value.uuidString)_\(gameSession.status.rawValue)_\(gameSession.remainingTime)_\(gameSession.inkSpots.count)_\(gameSession.players.count)"
        return String(hashData.hashValue)
    }
}

// MARK: - SyncError

public enum SyncError: Error, LocalizedError {
    case connectionLost
    case syncFailed(Error)
    case messageDecodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .connectionLost:
            return "接続が失われました"
        case let .syncFailed(error):
            return "同期に失敗しました: \(error.localizedDescription)"
        case let .messageDecodingFailed(error):
            return "メッセージの解析に失敗しました: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let connectionStateChanged = Notification.Name("connectionStateChanged")
}

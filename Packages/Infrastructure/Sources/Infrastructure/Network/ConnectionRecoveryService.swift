//
//  ConnectionRecoveryService.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

import Foundation
import MultipeerConnectivity

// MARK: - ConnectionRecoveryService

/// Service for handling connection recovery and resilience
public class ConnectionRecoveryService {
    // MARK: - Properties

    private let gameRepository: MultiPeerGameRepository
    private let maxRetryAttempts: Int
    private let retryInterval: TimeInterval
    private let exponentialBackoffMultiplier: Double

    // MARK: - State Properties

    public private(set) var isRecovering: Bool = false {
        didSet {
            onStateChanged?()
        }
    }

    public private(set) var retryAttempts: Int = 0 {
        didSet {
            onStateChanged?()
        }
    }

    public private(set) var lastRecoveryError: RecoveryError? {
        didSet {
            onStateChanged?()
        }
    }

    // MARK: - Callbacks

    public var onStateChanged: (() -> Void)?

    // MARK: - Recovery State

    private var recoveryTimer: Timer?
    private var currentRetryInterval: TimeInterval
    private var lastKnownPeers: [MCPeerID] = []
    private var connectionLostTimestamp: Date?

    // MARK: - Initialization

    public init(
        gameRepository: MultiPeerGameRepository,
        maxRetryAttempts: Int = 5,
        retryInterval: TimeInterval = 2.0,
        exponentialBackoffMultiplier: Double = 1.5
    ) {
        self.gameRepository = gameRepository
        self.maxRetryAttempts = maxRetryAttempts
        self.retryInterval = retryInterval
        self.exponentialBackoffMultiplier = exponentialBackoffMultiplier
        currentRetryInterval = retryInterval

        setupObservers()
    }

    deinit {
        stopRecovery()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(connectionStateChanged),
            name: .connectionStateChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(peerDisconnected(_:)),
            name: .peerDisconnected,
            object: nil
        )
    }

    @objc private func connectionStateChanged() {
        DispatchQueue.main.async {
            switch self.gameRepository.connectionState {
            case .connected:
                self.onConnectionRestored()
            case .disconnected:
                self.onConnectionLost()
            default:
                break
            }
        }
    }

    @objc private func peerDisconnected(_ notification: Notification) {
        if let peerID = notification.userInfo?["peerID"] as? MCPeerID {
            handlePeerDisconnection(peerID)
        }
    }

    // MARK: - Connection Recovery

    private func onConnectionLost() {
        guard !isRecovering else { return }

        connectionLostTimestamp = Date()
        lastKnownPeers = gameRepository.connectedPeers
        startRecovery()
    }

    private func onConnectionRestored() {
        stopRecovery()
        resetRecoveryState()

        // Notify successful recovery
        NotificationCenter.default.post(name: .connectionRecovered, object: nil)
    }

    private func handlePeerDisconnection(_ peerID: MCPeerID) {
        // Store peer for potential reconnection
        if !lastKnownPeers.contains(peerID) {
            lastKnownPeers.append(peerID)
        }

        // Start recovery if no peers are connected
        if gameRepository.connectedPeers.isEmpty {
            onConnectionLost()
        }
    }

    // MARK: - Recovery Logic

    private func startRecovery() {
        guard !isRecovering else { return }

        isRecovering = true
        retryAttempts = 0
        currentRetryInterval = retryInterval

        scheduleRecoveryAttempt()
    }

    private func stopRecovery() {
        recoveryTimer?.invalidate()
        recoveryTimer = nil
        isRecovering = false
    }

    private func scheduleRecoveryAttempt() {
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: currentRetryInterval, repeats: false) { [weak self] _ in
            self?.attemptRecovery()
        }
    }

    private func attemptRecovery() {
        guard retryAttempts < maxRetryAttempts else {
            handleRecoveryFailure(.maxRetriesExceeded)
            return
        }

        retryAttempts += 1

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.performRecoveryAttempt()

                // Schedule next attempt if still not connected
                if self.gameRepository.connectionState != .connected {
                    DispatchQueue.main.async {
                        self.scheduleNextAttempt()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.handleRecoveryError(error)
                }
            }
        }
    }

    private func performRecoveryAttempt() throws {
        // Stop current networking activities
        gameRepository.stopAdvertising()
        gameRepository.stopBrowsing()

        // Wait a moment before restarting
        Thread.sleep(forTimeInterval: 0.5)

        // Restart networking
        gameRepository.startAdvertising()
        gameRepository.startBrowsing()

        // Try to reconnect to known peers
        for peerID in lastKnownPeers {
            gameRepository.invitePeer(peerID, timeout: 10.0)
        }
    }

    private func scheduleNextAttempt() {
        // Exponential backoff
        currentRetryInterval *= exponentialBackoffMultiplier

        // Cap the retry interval at 30 seconds
        currentRetryInterval = min(currentRetryInterval, 30.0)

        scheduleRecoveryAttempt()
    }

    private func handleRecoveryError(_ error: Error) {
        lastRecoveryError = .recoveryAttemptFailed(error)
        scheduleNextAttempt()
    }

    private func handleRecoveryFailure(_ error: RecoveryError) {
        DispatchQueue.main.async {
            self.lastRecoveryError = error
            self.stopRecovery()

            // Notify recovery failure
            NotificationCenter.default.post(
                name: .connectionRecoveryFailed,
                object: nil,
                userInfo: ["error": error]
            )
        }
    }

    private func resetRecoveryState() {
        retryAttempts = 0
        currentRetryInterval = retryInterval
        lastRecoveryError = nil
        connectionLostTimestamp = nil
    }

    // MARK: - Public API

    /// Manually trigger recovery attempt
    public func forceRecovery() {
        stopRecovery()
        startRecovery()
    }

    /// Get connection statistics
    public func getConnectionStats() -> ConnectionStats {
        let disconnectionDuration = connectionLostTimestamp.map { Date().timeIntervalSince($0) }

        return ConnectionStats(
            isConnected: gameRepository.connectionState == .connected,
            connectedPeersCount: gameRepository.connectedPeers.count,
            retryAttempts: retryAttempts,
            isRecovering: isRecovering,
            disconnectionDuration: disconnectionDuration
        )
    }

    /// Check if connection is stable
    public func isConnectionStable() -> Bool {
        gameRepository.connectionState == .connected && !isRecovering
    }
}

// MARK: - RecoveryError

public enum RecoveryError: Error, LocalizedError {
    case maxRetriesExceeded
    case recoveryAttemptFailed(Error)
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .maxRetriesExceeded:
            return "最大再試行回数に達しました"
        case let .recoveryAttemptFailed(error):
            return "復旧試行に失敗しました: \(error.localizedDescription)"
        case .networkUnavailable:
            return "ネットワークが利用できません"
        }
    }
}

// MARK: - ConnectionStats

public struct ConnectionStats {
    public let isConnected: Bool
    public let connectedPeersCount: Int
    public let retryAttempts: Int
    public let isRecovering: Bool
    public let disconnectionDuration: TimeInterval?

    public init(
        isConnected: Bool,
        connectedPeersCount: Int,
        retryAttempts: Int,
        isRecovering: Bool,
        disconnectionDuration: TimeInterval?
    ) {
        self.isConnected = isConnected
        self.connectedPeersCount = connectedPeersCount
        self.retryAttempts = retryAttempts
        self.isRecovering = isRecovering
        self.disconnectionDuration = disconnectionDuration
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let peerDisconnected = Notification.Name("peerDisconnected")
    static let connectionRecovered = Notification.Name("connectionRecovered")
    static let connectionRecoveryFailed = Notification.Name("connectionRecoveryFailed")
}

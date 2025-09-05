//
//  InkDataBatchProcessor.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

import Domain
import Foundation

// MARK: - InkDataBatchProcessor

/// Efficient batch processor for ink data synchronization
public class InkDataBatchProcessor {
    // MARK: - Properties

    private let batchSize: Int
    private let batchInterval: TimeInterval
    private var pendingInkSpots: [InkSpot] = []
    private var batchTimer: Timer?
    private let processQueue = DispatchQueue(label: "ink.batch.processor", qos: .userInitiated)

    // MARK: - Callbacks

    public var onBatchReady: (([InkSpot]) -> Void)?

    // MARK: - Initialization

    public init(batchSize: Int = 10, batchInterval: TimeInterval = 0.05) {
        self.batchSize = batchSize
        self.batchInterval = batchInterval
        startBatchTimer()
    }

    deinit {
        stopBatchTimer()
    }

    // MARK: - Batch Processing

    /// Add ink spot to batch queue
    public func addInkSpot(_ inkSpot: InkSpot) {
        processQueue.async {
            self.pendingInkSpots.append(inkSpot)

            // Process immediately if batch is full
            if self.pendingInkSpots.count >= self.batchSize {
                self.processBatch()
            }
        }
    }

    /// Add multiple ink spots to batch queue
    public func addInkSpots(_ inkSpots: [InkSpot]) {
        processQueue.async {
            self.pendingInkSpots.append(contentsOf: inkSpots)

            // Process in chunks if we have too many
            while self.pendingInkSpots.count >= self.batchSize {
                self.processBatch()
            }
        }
    }

    /// Force process current batch
    public func flushBatch() {
        processQueue.async {
            if !self.pendingInkSpots.isEmpty {
                self.processBatch()
            }
        }
    }

    private func processBatch() {
        guard !pendingInkSpots.isEmpty else { return }

        let batchToProcess = Array(pendingInkSpots.prefix(batchSize))
        pendingInkSpots.removeFirst(min(batchSize, pendingInkSpots.count))

        DispatchQueue.main.async {
            self.onBatchReady?(batchToProcess)
        }
    }

    // MARK: - Timer Management

    private func startBatchTimer() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { [weak self] _ in
            self?.processQueue.async {
                self?.processBatch()
            }
        }
    }

    private func stopBatchTimer() {
        batchTimer?.invalidate()
        batchTimer = nil
    }

    // MARK: - Compression

    /// Compress ink spots data for efficient transmission
    public static func compressInkSpots(_ inkSpots: [InkSpot]) throws -> Data {
        let networkInkSpots = inkSpots.map { inkSpot in
            let rgbValues = inkSpot.color.rgbValues
            return NetworkInkSpot(
                id: inkSpot.id.value.uuidString,
                position: NetworkPosition3D(
                    x: inkSpot.position.x,
                    y: inkSpot.position.y,
                    z: inkSpot.position.z
                ),
                color: NetworkPlayerColor(
                    red: Double(rgbValues.red),
                    green: Double(rgbValues.green),
                    blue: Double(rgbValues.blue),
                    alpha: 1.0
                ),
                playerId: inkSpot.ownerId.value.uuidString
            )
        }

        let batchData = InkSpotBatch(inkSpots: networkInkSpots, timestamp: Date())
        let jsonData = try JSONEncoder().encode(batchData)

        // Compress using zlib
        return try jsonData.compressed()
    }

    /// Decompress ink spots data
    public static func decompressInkSpots(from data: Data) throws -> [NetworkInkSpot] {
        let decompressedData = try data.decompressed()
        let batchData = try JSONDecoder().decode(InkSpotBatch.self, from: decompressedData)
        return batchData.inkSpots
    }
}

// MARK: - InkSpotBatch

/// Batch container for ink spots
public struct InkSpotBatch: Codable {
    public let inkSpots: [NetworkInkSpot]
    public let timestamp: Date

    public init(inkSpots: [NetworkInkSpot], timestamp: Date) {
        self.inkSpots = inkSpots
        self.timestamp = timestamp
    }
}

// MARK: - Data Compression Extension

extension Data {
    /// Compress data using simple gzip-like compression (placeholder)
    func compressed() throws -> Data {
        // For now, return the original data
        // In a production app, you would implement proper compression
        self
    }

    /// Decompress data (placeholder)
    func decompressed() throws -> Data {
        // For now, return the original data
        // In a production app, you would implement proper decompression
        self
    }
}

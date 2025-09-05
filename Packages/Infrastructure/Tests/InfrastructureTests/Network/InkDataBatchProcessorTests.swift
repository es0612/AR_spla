//
//  InkDataBatchProcessorTests.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

@testable import Domain
import Foundation
@testable import Infrastructure
import Testing
@testable import TestSupport

struct InkDataBatchProcessorTests {
    @Test("バッチプロセッサの初期化")
    func testInitialization() {
        let processor = InkDataBatchProcessor(batchSize: 5, batchInterval: 0.1)

        #expect(processor.onBatchReady == nil)
    }

    @Test("単一インクスポットの追加")
    func testAddSingleInkSpot() async {
        let processor = InkDataBatchProcessor(batchSize: 10, batchInterval: 1.0)
        var receivedBatches: [[InkSpot]] = []

        processor.onBatchReady = { inkSpots in
            receivedBatches.append(inkSpots)
        }

        let inkSpot = InkSpotBuilder()
            .withId(InkSpotId())
            .withPosition(Position3D(x: 1.0, y: 0.0, z: 1.0))
            .withColor(PlayerColor.red)
            .withOwnerId(PlayerId())
            .build()

        processor.addInkSpot(inkSpot)

        // バッチサイズに達していないので、まだ処理されない
        #expect(receivedBatches.isEmpty)
    }

    @Test("バッチサイズに達した時の処理")
    func testBatchSizeReached() async {
        let batchSize = 3
        let processor = InkDataBatchProcessor(batchSize: batchSize, batchInterval: 1.0)
        var receivedBatches: [[InkSpot]] = []

        processor.onBatchReady = { inkSpots in
            receivedBatches.append(inkSpots)
        }

        // バッチサイズ分のインクスポットを追加
        for i in 0 ..< batchSize {
            let inkSpot = InkSpotBuilder()
                .withId(InkSpotId())
                .withPosition(Position3D(x: Float(i), y: 0.0, z: 0.0))
                .withColor(PlayerColor.red)
                .withOwnerId(PlayerId())
                .build()

            processor.addInkSpot(inkSpot)
        }

        // 少し待ってバッチ処理を確認
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        #expect(receivedBatches.count == 1)
        #expect(receivedBatches.first?.count == batchSize)
    }

    @Test("複数インクスポットの一括追加")
    func testAddMultipleInkSpots() async {
        let processor = InkDataBatchProcessor(batchSize: 5, batchInterval: 1.0)
        var receivedBatches: [[InkSpot]] = []

        processor.onBatchReady = { inkSpots in
            receivedBatches.append(inkSpots)
        }

        let inkSpots = (0 ..< 7).map { i in
            InkSpotBuilder()
                .withId(InkSpotId())
                .withPosition(Position3D(x: Float(i), y: 0.0, z: 0.0))
                .withColor(PlayerColor.blue)
                .withOwnerId(PlayerId())
                .build()
        }

        processor.addInkSpots(inkSpots)

        // 少し待ってバッチ処理を確認
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        // 7個のインクスポットが5個と2個のバッチに分かれる
        #expect(receivedBatches.count >= 1)
    }

    @Test("強制フラッシュ")
    func testFlushBatch() async {
        let processor = InkDataBatchProcessor(batchSize: 10, batchInterval: 1.0)
        var receivedBatches: [[InkSpot]] = []

        processor.onBatchReady = { inkSpots in
            receivedBatches.append(inkSpots)
        }

        // バッチサイズに満たない数のインクスポットを追加
        let inkSpots = (0 ..< 3).map { i in
            InkSpotBuilder()
                .withId(InkSpotId())
                .withPosition(Position3D(x: Float(i), y: 0.0, z: 0.0))
                .withColor(PlayerColor.green)
                .withOwnerId(PlayerId())
                .build()
        }

        processor.addInkSpots(inkSpots)
        processor.flushBatch()

        // 少し待ってバッチ処理を確認
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        #expect(receivedBatches.count == 1)
        #expect(receivedBatches.first?.count == 3)
    }

    @Test("インクスポットデータの圧縮と展開")
    func testCompressionAndDecompression() throws {
        let inkSpots = (0 ..< 5).map { i in
            InkSpotBuilder()
                .withId(InkSpotId())
                .withPosition(Position3D(x: Float(i), y: 0.0, z: 0.0))
                .withColor(PlayerColor.red)
                .withOwnerId(PlayerId())
                .build()
        }

        // 圧縮
        let compressedData = try InkDataBatchProcessor.compressInkSpots(inkSpots)
        #expect(!compressedData.isEmpty)

        // 展開
        let decompressedInkSpots = try InkDataBatchProcessor.decompressInkSpots(from: compressedData)
        #expect(decompressedInkSpots.count == 5)

        // データの整合性確認
        for (index, networkInkSpot) in decompressedInkSpots.enumerated() {
            let originalInkSpot = inkSpots[index]
            #expect(networkInkSpot.position.x == originalInkSpot.position.x)
            #expect(networkInkSpot.position.y == originalInkSpot.position.y)
            #expect(networkInkSpot.position.z == originalInkSpot.position.z)
        }
    }
}

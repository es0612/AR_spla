//
//  CollisionDetectionServiceTests.swift
//  DomainTests
//
//  Created by Kiro on 2025-01-09.
//

@testable import Domain
import Testing

struct CollisionDetectionServiceTests {
    // MARK: - Test Data

    private let gameRules = GameRules.default
    private let service = CollisionDetectionService(gameRules: .default)

    private let player1 = Player(
        id: PlayerId(),
        name: "Player1",
        color: .red,
        position: Position3D(x: 0, y: 0, z: 0)
    )

    private let player2 = Player(
        id: PlayerId(),
        name: "Player2",
        color: .blue,
        position: Position3D(x: 2, y: 0, z: 0)
    )

    // MARK: - Player-Ink Collision Tests

    @Test("プレイヤーとインクスポットの衝突判定 - 衝突あり")
    func testPlayerInkCollision_WithCollision() {
        // インクスポットをプレイヤーの近くに配置
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.3, y: 0, z: 0), // プレイヤーから0.3m
            color: .blue,
            size: 0.5,
            ownerId: player2.id
        )

        let result = service.checkPlayerInkCollision(player1, with: inkSpot)

        #expect(result.hasCollision == true)
        #expect(result.distance == 0.3)
        #expect(result.collisionPoint != nil)
    }

    @Test("プレイヤーとインクスポットの衝突判定 - 衝突なし")
    func testPlayerInkCollision_NoCollision() {
        // インクスポットをプレイヤーから離れた場所に配置
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 5, y: 0, z: 0), // プレイヤーから5m
            color: .blue,
            size: 0.5,
            ownerId: player2.id
        )

        let result = service.checkPlayerInkCollision(player1, with: inkSpot)

        #expect(result.hasCollision == false)
        #expect(result.distance == 5.0)
        #expect(result.collisionPoint == nil)
    }

    @Test("プレイヤーとインクスポットの衝突判定 - 自分のインク")
    func testPlayerInkCollision_OwnInk() {
        // プレイヤー自身のインクスポット
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.1, y: 0, z: 0),
            color: .red,
            size: 0.5,
            ownerId: player1.id // 同じプレイヤーのID
        )

        let result = service.checkPlayerInkCollision(player1, with: inkSpot)

        #expect(result.hasCollision == false)
    }

    @Test("プレイヤーとインクスポットの衝突判定 - 非アクティブプレイヤー")
    func testPlayerInkCollision_InactivePlayer() {
        let inactivePlayer = player1.deactivate()

        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.1, y: 0, z: 0),
            color: .blue,
            size: 0.5,
            ownerId: player2.id
        )

        let result = service.checkPlayerInkCollision(inactivePlayer, with: inkSpot)

        #expect(result.hasCollision == false)
    }

    @Test("複数インクスポットとの衝突判定")
    func testPlayerInkCollisions_Multiple() {
        let inkSpots = [
            InkSpot(id: InkSpotId(), position: Position3D(x: 0.3, y: 0, z: 0), color: .blue, size: 0.5, ownerId: player2.id),
            InkSpot(id: InkSpotId(), position: Position3D(x: 5, y: 0, z: 0), color: .blue, size: 0.5, ownerId: player2.id),
            InkSpot(id: InkSpotId(), position: Position3D(x: 0, y: 0, z: 0.4), color: .blue, size: 0.5, ownerId: player2.id)
        ]

        let collidingSpots = service.checkPlayerInkCollisions(player1, with: inkSpots)

        #expect(collidingSpots.count == 2) // 最初と3番目のインクスポット
    }

    // MARK: - Ink Spot Overlap Tests

    @Test("インクスポット重複判定 - 重複あり")
    func testInkSpotOverlap_WithOverlap() {
        let inkSpot1 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: player1.id
        )

        let inkSpot2 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1.5, y: 0, z: 0), // 1.5m離れている
            color: .blue,
            size: 1.0,
            ownerId: player2.id
        )

        let result = service.checkInkSpotOverlap(inkSpot1, inkSpot2)

        #expect(result.hasOverlap == true)
        #expect(result.overlapArea > 0)
        #expect(result.mergedSize == nil) // 異なる色なのでマージなし
    }

    @Test("インクスポット重複判定 - 同色でマージ")
    func testInkSpotOverlap_SameColorMerge() {
        let inkSpot1 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: player1.id
        )

        let inkSpot2 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1.0, y: 0, z: 0),
            color: .red, // 同じ色
            size: 1.0,
            ownerId: player1.id
        )

        let result = service.checkInkSpotOverlap(inkSpot1, inkSpot2)

        #expect(result.hasOverlap == true)
        #expect(result.mergedSize != nil)
        #expect(result.mergedSize! > 1.0) // マージ後のサイズは元より大きい
    }

    @Test("インクスポット重複判定 - 重複なし")
    func testInkSpotOverlap_NoOverlap() {
        let inkSpot1 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: player1.id
        )

        let inkSpot2 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 5, y: 0, z: 0), // 十分離れている
            color: .blue,
            size: 1.0,
            ownerId: player2.id
        )

        let result = service.checkInkSpotOverlap(inkSpot1, inkSpot2)

        #expect(result.hasOverlap == false)
        #expect(result.overlapArea == 0)
    }

    @Test("重複するインクスポットの検索")
    func testFindOverlappingInkSpots() {
        let targetInkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: player1.id
        )

        let inkSpots = [
            InkSpot(id: InkSpotId(), position: Position3D(x: 1.5, y: 0, z: 0), color: .blue, size: 1.0, ownerId: player2.id), // 重複
            InkSpot(id: InkSpotId(), position: Position3D(x: 5, y: 0, z: 0), color: .blue, size: 1.0, ownerId: player2.id), // 重複なし
            InkSpot(id: InkSpotId(), position: Position3D(x: 0, y: 0, z: 1.8), color: .red, size: 1.0, ownerId: player1.id) // 重複
        ]

        let overlaps = service.findOverlappingInkSpots(targetInkSpot, in: inkSpots)

        #expect(overlaps.count == 2)
    }

    // MARK: - Area-based Collision Tests

    @Test("位置がインクスポット内にあるかの判定")
    func testIsPositionInInkSpot() {
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: player1.id
        )

        let insidePosition = Position3D(x: 0.5, y: 0, z: 0)
        let outsidePosition = Position3D(x: 2, y: 0, z: 0)

        #expect(service.isPositionInInkSpot(insidePosition, inkSpot: inkSpot) == true)
        #expect(service.isPositionInInkSpot(outsidePosition, inkSpot: inkSpot) == false)
    }

    @Test("位置を含むインクスポットの検索")
    func testFindInkSpotsContaining() {
        let position = Position3D(x: 0, y: 0, z: 0)

        let inkSpots = [
            InkSpot(id: InkSpotId(), position: Position3D(x: 0, y: 0, z: 0), color: .red, size: 1.0, ownerId: player1.id), // 含む
            InkSpot(id: InkSpotId(), position: Position3D(x: 0.5, y: 0, z: 0), color: .blue, size: 1.0, ownerId: player2.id), // 含む
            InkSpot(id: InkSpotId(), position: Position3D(x: 5, y: 0, z: 0), color: .red, size: 1.0, ownerId: player1.id) // 含まない
        ]

        let containingSpots = service.findInkSpotsContaining(position, in: inkSpots)

        #expect(containingSpots.count == 2)
    }

    // MARK: - Collision Effect Tests

    @Test("プレイヤー衝突効果の計算")
    func testCalculatePlayerCollisionEffect() {
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.3, y: 0, z: 0),
            color: .blue,
            size: 1.0, // 大きなインクスポット
            ownerId: player2.id
        )

        let effect = service.calculatePlayerCollisionEffect(player1, with: inkSpot)

        #expect(effect.isStunned == true)
        #expect(effect.stunDuration > 0)
        #expect(effect.speedReduction > 0)
    }

    @Test("プレイヤー衝突効果 - 衝突なし")
    func testCalculatePlayerCollisionEffect_NoCollision() {
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 10, y: 0, z: 0), // 遠い位置
            color: .blue,
            size: 1.0,
            ownerId: player2.id
        )

        let effect = service.calculatePlayerCollisionEffect(player1, with: inkSpot)

        #expect(effect == .none)
        #expect(effect.isStunned == false)
    }

    @Test("インクスポットサイズによるスタン時間の変化")
    func testStunDurationVariation() {
        let smallInkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.3, y: 0, z: 0),
            color: .blue,
            size: InkSpot.minSize,
            ownerId: player2.id
        )

        let largeInkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.3, y: 0, z: 0),
            color: .blue,
            size: InkSpot.maxSize,
            ownerId: player2.id
        )

        let smallEffect = service.calculatePlayerCollisionEffect(player1, with: smallInkSpot)
        let largeEffect = service.calculatePlayerCollisionEffect(player1, with: largeInkSpot)

        #expect(largeEffect.stunDuration > smallEffect.stunDuration)
        #expect(largeEffect.speedReduction > smallEffect.speedReduction)
    }
}

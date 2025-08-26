# Design Document

## Overview

ARスプラトゥーンゲームは、ARKitとRealityKitを活用したiOSネイティブアプリケーションです。SwiftUIを使用してユーザーインターフェースを構築し、Multipeer Connectivityを通じてローカル通信による一対一の対戦機能を提供します。プレイヤーは現実空間に投影されたゲームフィールドで、インクを撃ち合い、陣地を塗り合う対戦ゲームを楽しめます。

## Architecture

### アプリケーション構造

```
ARSplatoonGame/
├── project.yml                          # XcodeGen設定ファイル
├── Makefile                             # ビルド・開発タスク自動化
├── .gitignore                           # Git除外設定（.xcodeproj含む）
├── Sources/
│   ├── App/
│   │   ├── ARSplatoonGameApp.swift      # メインアプリエントリーポイント
│   │   └── ContentView.swift            # ルートビュー
│   ├── Views/
│   │   ├── MenuView.swift               # メインメニュー
│   │   ├── ARGameView.swift             # ARゲーム画面
│   │   ├── GameResultView.swift         # 結果画面
│   │   └── SettingsView.swift           # 設定画面
│   ├── AR/
│   │   ├── ARViewController.swift       # ARセッション管理
│   │   └── ARGameViewRepresentable.swift # SwiftUI-UIKit Bridge
│   └── Data/
│       ├── GameDataModel.swift          # SwiftData モデル定義
│       └── DataContainer.swift          # SwiftData コンテナ設定
├── Resources/
│   ├── Assets.xcassets/                 # アプリアイコン・画像リソース
│   ├── Localizable.strings              # 多言語対応文字列
│   ├── PrivacyInfo.xcprivacy           # プライバシーマニフェスト
│   └── Info.plist                       # アプリ設定情報
├── Tests/
│   ├── ARSplatoonGameTests/             # アプリレベルのテスト
│   └── ARSplatoonGameUITests/           # UIテスト
└── Packages/
    ├── Domain/                          # ドメイン層 SPMパッケージ
    │   ├── Package.swift
    │   ├── Sources/Domain/
    │   │   ├── Entities/
    │   │   │   ├── Player.swift
    │   │   │   ├── InkSpot.swift
    │   │   │   └── GameSession.swift
    │   │   ├── ValueObjects/
    │   │   │   ├── PlayerId.swift
    │   │   │   ├── Position3D.swift
    │   │   │   └── GameScore.swift
    │   │   ├── Services/
    │   │   │   ├── GameRuleService.swift
    │   │   │   └── ScoreCalculationService.swift
    │   │   └── Repositories/
    │   │       ├── GameRepository.swift
    │   │       └── PlayerRepository.swift
    │   └── Tests/DomainTests/
    │       ├── Entities/
    │       ├── ValueObjects/
    │       └── Services/
    ├── Application/                     # アプリケーション層 SPMパッケージ
    │   ├── Package.swift
    │   ├── Sources/Application/
    │   │   ├── UseCases/
    │   │   │   ├── StartGameUseCase.swift
    │   │   │   ├── ShootInkUseCase.swift
    │   │   │   └── CalculateScoreUseCase.swift
    │   │   ├── Coordinators/
    │   │   │   └── GameCoordinator.swift
    │   │   └── DTOs/
    │   │       └── GameStateDTO.swift
    │   └── Tests/ApplicationTests/
    │       └── UseCases/
    ├── Infrastructure/                  # インフラ層 SPMパッケージ
    │   ├── Package.swift
    │   ├── Sources/Infrastructure/
    │   │   ├── Network/
    │   │   │   ├── MultiPeerGameRepository.swift
    │   │   │   └── NetworkGameMessage.swift
    │   │   ├── AR/
    │   │   │   ├── ARGameFieldRepository.swift
    │   │   │   └── ARInkRenderer.swift
    │   │   └── Persistence/
    │   │       └── SwiftDataGameRepository.swift
    │   └── Tests/InfrastructureTests/
    │       ├── Network/
    │       ├── AR/
    │       └── Persistence/
    └── TestSupport/                     # テスト支援 SPMパッケージ
        ├── Package.swift
        ├── Sources/TestSupport/
        │   ├── Mocks/
        │   │   ├── MockGameRepository.swift
        │   │   └── MockPlayerRepository.swift
        │   ├── Builders/
        │   │   ├── PlayerBuilder.swift
        │   │   └── GameSessionBuilder.swift
        │   └── Fixtures/
        │       └── TestData.swift
        └── Tests/TestSupportTests/
```

### アーキテクチャパターン

#### クリーンアーキテクチャの採用

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                   │
│  (SwiftUI Views, ViewModels, @Observable State)         │
├─────────────────────────────────────────────────────────┤
│                   Application Layer                     │
│     (Use Cases, Game Coordinators, Event Handlers)     │
├─────────────────────────────────────────────────────────┤
│                     Domain Layer                        │
│    (Entities, Value Objects, Domain Services)          │
├─────────────────────────────────────────────────────────┤
│                  Infrastructure Layer                   │
│  (ARKit, MultipeerConnectivity, SwiftData, Network)    │
└─────────────────────────────────────────────────────────┘
```

- **依存関係の逆転**: 外側の層が内側の層に依存、内側は外側を知らない
- **テスタビリティ**: ドメインロジックの完全な分離とテスト容易性
- **Modular Architecture**: SPMローカルパッケージによる物理的な分離
- **Observation Framework**: iOS 17+の@Observableマクロを使用した状態管理

## Components and Interfaces

### 1. AR Components

#### ARViewController
```swift
class ARViewController: UIViewController, ARSessionDelegate {
    var arView: ARView
    var gameFieldManager: GameFieldManager
    var inkSystem: InkSystem
    
    func startARSession()
    func stopARSession()
    func handleTap(at location: CGPoint)
}
```

#### GameFieldManager
```swift
class GameFieldManager: ObservableObject {
    @Published var fieldSize: CGSize
    @Published var fieldPosition: simd_float3
    
    func setupGameField(on anchor: ARAnchor)
    func calculatePaintedArea(for player: Player) -> Float
}
```

#### InkSystem
```swift
class InkSystem: ObservableObject {
    func shootInk(from position: simd_float3, direction: simd_float3, color: UIColor)
    func addInkSpot(at position: simd_float3, color: UIColor, size: Float)
    func checkInkCollision(with player: Player) -> Bool
}
```

### 2. Networking Components

#### MultiPeerManager
```swift
@Observable
class MultiPeerManager: NSObject {
    var connectedPeers: [MCPeerID] = []
    var connectionState: ConnectionState = .disconnected
    
    func startAdvertising()
    func startBrowsing()
    func sendGameMessage(_ message: GameMessage)
}
```

#### GameMessage
```swift
struct GameMessage: Codable {
    enum MessageType: String, Codable {
        case inkShot, playerPosition, gameStart, gameEnd
    }
    
    let type: MessageType
    let data: Data
    let timestamp: Date
}
```

### 3. Game Logic Components

#### GameState
```swift
@Observable
class GameState {
    var currentPhase: GamePhase = .waiting
    var timeRemaining: TimeInterval = 180
    var players: [Player] = []
    var inkSpots: [InkSpot] = []
    
    func startGame()
    func endGame()
    func calculateWinner() -> Player?
}
```

#### Player
```swift
struct Player: Identifiable, Codable {
    let id: UUID
    let name: String
    let color: UIColor
    var position: simd_float3
    var isActive: Bool
    var paintedArea: Float
}
```

## Data Models

### Core Models

```swift
// ゲームフェーズ
enum GamePhase: String, CaseIterable {
    case waiting = "waiting"
    case connecting = "connecting"
    case playing = "playing"
    case finished = "finished"
}

// 接続状態
enum ConnectionState: String {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
}

// インクスポット
struct InkSpot: Identifiable, Codable {
    let id: UUID
    let position: simd_float3
    let color: UIColor
    let size: Float
    let timestamp: Date
}

// ゲーム設定
struct GameSettings: Codable {
    var gameDuration: TimeInterval = 180
    var inkShotCooldown: TimeInterval = 0.5
    var playerStunDuration: TimeInterval = 3.0
    var fieldSize: CGSize = CGSize(width: 4.0, height: 4.0)
}
```

### データ永続化

```swift
// SwiftData モデル
@Model
class GameHistory {
    var id: UUID
    var date: Date
    var duration: TimeInterval
    var winner: String
    var playerScore: Float
    var opponentScore: Float
    
    init(id: UUID = UUID(), date: Date = Date(), duration: TimeInterval, winner: String, playerScore: Float, opponentScore: Float) {
        self.id = id
        self.date = date
        self.duration = duration
        self.winner = winner
        self.playerScore = playerScore
        self.opponentScore = opponentScore
    }
}

@Model
class PlayerProfile {
    var name: String
    var totalGames: Int
    var wins: Int
    var totalPaintedArea: Float
    
    init(name: String, totalGames: Int = 0, wins: Int = 0, totalPaintedArea: Float = 0) {
        self.name = name
        self.totalGames = totalGames
        self.wins = wins
        self.totalPaintedArea = totalPaintedArea
    }
}
```

- **SwiftData**: ゲーム履歴とプレイヤープロファイルの永続化
- **UserDefaults**: 軽量な設定データの保存

## Error Handling

### ARKit関連エラー

```swift
enum ARError: Error, LocalizedError {
    case sessionFailed
    case trackingLimited
    case planeDetectionFailed
    case unsupportedDevice
    
    var errorDescription: String? {
        switch self {
        case .sessionFailed:
            return "ARセッションの開始に失敗しました"
        case .trackingLimited:
            return "トラッキングが制限されています"
        case .planeDetectionFailed:
            return "平面の検出に失敗しました"
        case .unsupportedDevice:
            return "このデバイスはARをサポートしていません"
        }
    }
}
```

### ネットワーク関連エラー

```swift
enum NetworkError: Error, LocalizedError {
    case connectionFailed
    case peerDisconnected
    case messageDecodingFailed
    case sendingFailed
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "接続に失敗しました"
        case .peerDisconnected:
            return "相手プレイヤーとの接続が切断されました"
        case .messageDecodingFailed:
            return "メッセージの解析に失敗しました"
        case .sendingFailed:
            return "メッセージの送信に失敗しました"
        }
    }
}
```

### エラーハンドリング戦略

1. **Graceful Degradation**: 機能の一部が利用できない場合でも、可能な限りアプリを継続
2. **User Feedback**: エラー発生時は分かりやすいメッセージでユーザーに通知
3. **Automatic Recovery**: 可能な場合は自動的に復旧を試行
4. **Logging**: デバッグ用のログ出力

## Testing Strategy

### Unit Testing

- **Game Logic**: ゲーム状態管理、スコア計算、勝敗判定
- **Network Protocol**: メッセージのエンコード/デコード
- **Utility Functions**: 座標変換、衝突判定

### Integration Testing

- **AR Integration**: ARKitとゲームロジックの統合
- **Network Integration**: Multipeer Connectivityとゲーム状態の同期
- **UI Integration**: SwiftUIビューとゲーム状態の連携

### UI Testing

- **Menu Navigation**: メニュー画面の操作
- **Game Flow**: ゲーム開始から終了までの流れ
- **Error Scenarios**: エラー発生時のUI表示

### Performance Testing

- **AR Rendering**: フレームレート維持
- **Network Latency**: メッセージ送受信の遅延測定
- **Memory Usage**: メモリリークの検出

### Testing Tools

- **Swift Testing**: モダンなテストフレームワーク（iOS 18+対応）
- **XCTest**: 従来のユニットテスト（互換性維持）
- **XCUITest**: UIテスト
- **Instruments**: パフォーマンス測定
- **Network Link Conditioner**: ネットワーク状況のシミュレーション

### SPMパッケージのテスト戦略

```swift
// Swift Testing を使用したテスト例
import Testing
@testable import GameCore

struct GameStateTests {
    @Test("ゲーム開始時の状態確認")
    func testGameStart() {
        let gameState = GameState()
        gameState.startGame()
        
        #expect(gameState.currentPhase == .playing)
        #expect(gameState.timeRemaining == 180)
    }
    
    @Test("スコア計算の正確性", arguments: [
        (10.0, 5.0, "Player1"),
        (3.0, 8.0, "Player2"),
        (5.0, 5.0, nil)
    ])
    func testScoreCalculation(player1Score: Float, player2Score: Float, expectedWinner: String?) {
        let calculator = ScoreCalculator()
        let result = calculator.determineWinner(player1Score: player1Score, player2Score: player2Score)
        
        #expect(result == expectedWinner)
    }
}
```

### TDD開発戦略（t-wada流）

#### テストファースト開発サイクル

```
Red → Green → Refactor → Tidy
 ↑                        ↓
 ←←←←←←←←←←←←←←←←←←←←←←←←←←←
```

1. **Red**: 失敗するテストを書く（仕様の明確化）
2. **Green**: 最小限のコードでテストを通す（動作する実装）
3. **Refactor**: コードの構造を改善（設計の改善）
4. **Tidy**: 小さな整理整頓（Kent Beck's Tidy First）

#### テスト戦略の階層化

```swift
// 1. ドメインロジックのテスト（最重要・高速）
@Test("スコア計算の正確性")
func testScoreCalculation() {
    let service = ScoreCalculationService()
    let result = service.calculate(playerArea: 60.0, opponentArea: 40.0)
    #expect(result.winner == .player)
}

// 2. ユースケースのテスト（統合・中速）
@Test("ゲーム開始ユースケース")
func testStartGameUseCase() async {
    let mockRepo = MockGameRepository()
    let useCase = StartGameUseCase(repository: mockRepo)
    
    await useCase.execute(players: [player1, player2])
    
    #expect(mockRepo.savedGame != nil)
}

// 3. UIテスト（E2E・低速）
func testGameFlow() {
    // XCUITest による画面操作テスト
}
```

#### Tidy First の実践

1. **Guard Clauses**: 早期リターンによる可読性向上
2. **Dead Code Elimination**: 使われないコードの削除
3. **Normalize Symmetries**: 対称性の正規化
4. **New Interface, Old Implementation**: インターフェース改善の段階的適用

```swift
// Before: 複雑な条件分岐
func calculateWinner(player1Score: Float, player2Score: Float) -> String? {
    if player1Score > player2Score {
        return "Player1"
    } else if player2Score > player1Score {
        return "Player2"
    } else {
        return nil
    }
}

// After: Guard Clauses + Value Object
func calculateWinner(score1: GameScore, score2: GameScore) -> Winner? {
    guard score1 != score2 else { return nil }
    return score1 > score2 ? .player1 : .player2
}
```

## Technical Considerations

### ARKit最適化

- **平面検出**: 水平面の検出精度向上
- **オクルージョン**: 現実オブジェクトとの重なり処理
- **ライティング**: 環境光の推定と反映

### ネットワーク最適化

- **メッセージ圧縮**: 大量のインクデータの効率的な送信
- **同期戦略**: ゲーム状態の一貫性保持
- **接続復旧**: 一時的な切断からの自動復旧

### パフォーマンス最適化

- **描画最適化**: インクスポットの効率的なレンダリング
- **メモリ管理**: 大量のARオブジェクトの適切な管理
- **バッテリー効率**: AR処理による電力消費の最小化
## SP
Mローカルパッケージ戦略の利点

### 開発効率の向上

1. **高速テスト実行**: `swift test`によるシミュレータ不要のテスト
2. **モジュール分離**: 機能ごとの独立開発とテスト
3. **TDD促進**: 高速フィードバックループの実現

### コード品質の向上

1. **依存関係の明確化**: パッケージ間の依存関係が明示的
2. **再利用性**: 他のプロジェクトでの再利用可能
3. **テスタビリティ**: 各モジュールの独立したテスト

### パッケージ構成

#### GameCore パッケージ
- **責務**: ゲームロジック、スコア計算、状態管理
- **依存関係**: Foundation のみ
- **テスト**: 高速なユニットテスト

#### NetworkCore パッケージ  
- **責務**: Multipeer Connectivity、メッセージング
- **依存関係**: Foundation、MultipeerConnectivity
- **テスト**: ネットワーク通信のモックテスト

#### ARCore パッケージ
- **責務**: AR座標系、衝突判定、空間計算
- **依存関係**: Foundation、simd
- **テスト**: 数学的計算のテスト（ARKit依存部分は除く）

### 開発ワークフロー

#### TDDサイクルの実践

```bash
# 1. ドメイン層の高速テスト（秒単位）
cd Packages/Domain && swift test

# 2. アプリケーション層のテスト（秒単位）
cd Packages/Application && swift test

# 3. インフラ層のテスト（分単位）
cd Packages/Infrastructure && swift test

# 4. 統合テスト（分単位）
xcodebuild test -scheme ARSplatoonGame

# 5. 継続的テスト実行
fswatch -o . | xargs -n1 -I{} swift test
```

#### クリーンアーキテクチャの依存関係管理

```swift
// Package.swift での依存関係定義
let package = Package(
    name: "Application",
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../TestSupport")
    ],
    targets: [
        .target(
            name: "Application",
            dependencies: ["Domain"]
        ),
        .testTarget(
            name: "ApplicationTests",
            dependencies: ["Application", "TestSupport"]
        )
    ]
)
```

#### 段階的リファクタリング戦略

1. **Make the change easy**: 変更しやすい構造に整理
2. **Make the easy change**: 実際の変更を実施
3. **Tidy up**: 小さな整理整頓を継続
4. **Repeat**: サイクルを繰り返す
## Xc
odeGen プロジェクト管理

### XcodeGen設定ファイル (project.yml)

```yaml
name: ARSplatoonGame
options:
  bundleIdPrefix: com.yourcompany
  deploymentTarget:
    iOS: "17.0"
  developmentLanguage: ja
  
settings:
  base:
    SWIFT_VERSION: "5.9"
    IPHONEOS_DEPLOYMENT_TARGET: "17.0"
    TARGETED_DEVICE_FAMILY: "1"
    SUPPORTS_MACCATALYST: false
    
targets:
  ARSplatoonGame:
    type: application
    platform: iOS
    sources:
      - path: Sources
        excludes:
          - "**/*.md"
    resources:
      - path: Resources
        excludes:
          - "**/.DS_Store"
    dependencies:
      - package: Domain
      - package: Application  
      - package: Infrastructure
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.yourcompany.arsplatoongame
        INFOPLIST_FILE: Resources/Info.plist
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        SWIFT_EMIT_LOC_STRINGS: true
      configs:
        Debug:
          SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG
        Release:
          SWIFT_COMPILATION_MODE: wholemodule
          
  ARSplatoonGameTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: Tests/ARSplatoonGameTests
    dependencies:
      - target: ARSplatoonGame
      - package: TestSupport
      
  ARSplatoonGameUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - path: Tests/ARSplatoonGameUITests
    dependencies:
      - target: ARSplatoonGame

packages:
  Domain:
    path: Packages/Domain
  Application:
    path: Packages/Application
  Infrastructure:
    path: Packages/Infrastructure
  TestSupport:
    path: Packages/TestSupport

schemes:
  ARSplatoonGame:
    build:
      targets:
        ARSplatoonGame: all
        ARSplatoonGameTests: [test]
        ARSplatoonGameUITests: [test]
    run:
      config: Debug
    test:
      config: Debug
      targets:
        - ARSplatoonGameTests
        - ARSplatoonGameUITests
    archive:
      config: Release
```

### Makefile による開発タスク自動化

```makefile
.PHONY: setup generate build test clean install-tools

# 開発環境セットアップ
setup: install-tools generate

# 必要なツールのインストール
install-tools:
	@echo "Installing development tools..."
	brew install xcodegen
	brew install swiftformat
	brew install swiftlint

# Xcodeプロジェクトの生成
generate:
	@echo "Generating Xcode project..."
	xcodegen generate

# プロジェクトのビルド
build:
	@echo "Building project..."
	xcodebuild -scheme ARSplatoonGame -configuration Debug build

# テストの実行
test:
	@echo "Running tests..."
	# SPMパッケージの高速テスト
	cd Packages/Domain && swift test
	cd Packages/Application && swift test
	cd Packages/Infrastructure && swift test
	# 統合テスト
	xcodebuild test -scheme ARSplatoonGame -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# コードフォーマット
format:
	@echo "Formatting code..."
	swiftformat Sources/ Packages/
	swiftlint --fix

# プロジェクトのクリーンアップ
clean:
	@echo "Cleaning project..."
	rm -rf ARSplatoonGame.xcodeproj
	rm -rf DerivedData
	xcodebuild clean

# 新しいパッケージの作成
create-package:
	@read -p "Package name: " name; \
	mkdir -p Packages/$$name/Sources/$$name; \
	mkdir -p Packages/$$name/Tests/$${name}Tests; \
	echo "// swift-tools-version: 5.9\nimport PackageDescription\n\nlet package = Package(\n    name: \"$$name\",\n    platforms: [.iOS(.v17)],\n    products: [\n        .library(name: \"$$name\", targets: [\"$$name\"])\n    ],\n    targets: [\n        .target(name: \"$$name\"),\n        .testTarget(name: \"$${name}Tests\", dependencies: [\"$$name\"])\n    ]\n)" > Packages/$$name/Package.swift

# 開発サーバーの起動（ファイル監視）
dev:
	@echo "Starting development mode with file watching..."
	fswatch -o Sources/ Packages/ | xargs -n1 -I{} make test-quick

# 高速テスト（SPMパッケージのみ）
test-quick:
	@echo "Running quick tests..."
	cd Packages/Domain && swift test
	cd Packages/Application && swift test
	cd Packages/Infrastructure && swift test
```

### .gitignore設定

```gitignore
# Xcode
*.xcodeproj/
!*.xcodeproj/project.xcworkspace/
!*.xcodeproj/xcshareddata/
*.xcworkspace/
!default.xcworkspace/

# XcodeGen
project.yml.lock

# Build products
DerivedData/
build/

# Swift Package Manager
.swiftpm/
Packages/*/Package.resolved

# CocoaPods
Pods/
*.podspec

# Carthage
Carthage/

# Accio dependency management
Dependencies/
.accio/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
iOSInjectionProject/
```

### 開発ワークフローの改善

#### プロジェクト初期化
```bash
# リポジトリクローン後の初期セットアップ
make setup
```

#### 日常的な開発フロー
```bash
# コード変更後
make format          # コードフォーマット
make test-quick      # 高速テスト
make generate        # プロジェクト再生成（必要時）
```

#### CI/CD統合
```bash
# CI環境での実行
make install-tools
make generate
make test
```

### XcodeGenの利点

1. **バージョン管理**: プロジェクト設定をYAMLで管理
2. **チーム開発**: プロジェクトファイルの競合回避
3. **一貫性**: 設定の標準化と自動化
4. **保守性**: 設定変更の追跡可能性
5. **CI/CD**: 自動化されたプロジェクト生成
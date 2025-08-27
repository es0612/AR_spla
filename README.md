# ARSplatoonGame

ARでスプラトゥーンのような対戦ゲームをiOSネイティブアプリとして開発するプロジェクトです。SwiftUIとARKitを使用し、まずは一対一のローカル通信対戦機能を実装します。

## 必要な環境

- macOS 14.0以降
- Xcode 15.0以降
- iOS 17.0以降対応デバイス（ARKit対応）
- Homebrew

## セットアップ

### 1. 開発ツールのインストール

```bash
make install-tools
```

このコマンドで以下のツールがインストールされます：
- XcodeGen: Xcodeプロジェクトファイルの生成
- SwiftFormat: コードフォーマッター
- SwiftLint: コード品質チェック

### 2. プロジェクトの生成

```bash
make generate
```

または

```bash
xcodegen generate
```

### 3. プロジェクトを開く

```bash
open ARSplatoonGame.xcodeproj
```

## 開発ワークフロー

### 基本的な開発フロー

```bash
# コードフォーマット
make format

# 高速テスト（SPMパッケージのみ）
make test-quick

# 全テスト実行
make test

# プロジェクトビルド
make build

# プロジェクトクリーンアップ
make clean
```

### ファイル監視モード

```bash
make dev
```

ファイル変更を監視して自動的にテストを実行します。

## プロジェクト構造

```
ARSplatoonGame/
├── project.yml                 # XcodeGen設定
├── Makefile                   # 開発タスク自動化
├── Sources/                   # メインアプリケーションコード
├── Resources/                 # リソースファイル
├── Tests/                     # テストファイル
└── Packages/                  # SPMローカルパッケージ
    ├── Domain/               # ドメイン層
    ├── Application/          # アプリケーション層
    ├── Infrastructure/       # インフラ層
    └── TestSupport/          # テスト支援
```

## アーキテクチャ

- **クリーンアーキテクチャ**: ドメイン駆動設計に基づく層分離
- **SPMローカルパッケージ**: モジュール分離とテスト高速化
- **TDD**: テスト駆動開発による品質保証
- **XcodeGen**: プロジェクト設定のコード管理

## 技術スタック

- **UI**: SwiftUI + @Observable
- **AR**: ARKit + RealityKit
- **ネットワーク**: Multipeer Connectivity
- **データ**: SwiftData
- **テスト**: Swift Testing + XCTest
- **ツール**: XcodeGen, SwiftFormat, SwiftLint

## 開発ガイドライン

### コード品質

- SwiftLintルールに従う
- SwiftFormatで自動フォーマット
- テストカバレッジ80%以上を目標

### Git運用

- `.xcodeproj`ファイルはGit管理対象外
- `project.yml`でプロジェクト設定を管理
- フィーチャーブランチでの開発

## トラブルシューティング

### XcodeGenでプロジェクト生成に失敗する場合

```bash
make clean
make generate
```

### ビルドエラーが発生する場合

```bash
# 依存関係をクリーン
rm -rf .build
make generate
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
.PHONY: setup generate build test clean install-tools format dev test-quick create-package

# 開発環境セットアップ
setup: install-tools generate

# 必要なツールのインストール
install-tools:
	@echo "Installing development tools..."
	@command -v brew >/dev/null 2>&1 || { echo "Homebrew is required but not installed. Please install Homebrew first."; exit 1; }
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
	@command -v fswatch >/dev/null 2>&1 || { echo "fswatch is required. Install with: brew install fswatch"; exit 1; }
	fswatch -o Sources/ Packages/ | xargs -n1 -I{} make test-quick

# 高速テスト（SPMパッケージのみ）
test-quick:
	@echo "Running quick tests..."
	@if [ -d "Packages/Domain" ]; then cd Packages/Domain && swift test; fi
	@if [ -d "Packages/Application" ]; then cd Packages/Application && swift test; fi
	@if [ -d "Packages/Infrastructure" ]; then cd Packages/Infrastructure && swift test; fi
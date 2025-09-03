# Technology Stack

## Build System
- **XcodeGen**: Project file generation from `project.yml` configuration
- **Swift Package Manager**: Local packages for modular architecture
- **Makefile**: Development workflow automation

## Core Technologies
- **Swift 5.9**: Primary programming language
- **iOS 17.0+**: Minimum deployment target
- **SwiftUI**: UI framework with @Observable state management
- **ARKit + RealityKit**: Augmented reality and 3D rendering
- **SwiftData**: Data persistence layer
- **Multipeer Connectivity**: Local network multiplayer

## Development Tools
- **SwiftLint**: Code quality and style enforcement
- **SwiftFormat**: Automatic code formatting
- **Swift Testing + XCTest**: Testing frameworks

## Common Commands

### Project Setup
```bash
# Install development tools
make install-tools

# Generate Xcode project
make generate

# Complete setup
make setup
```

### Development Workflow
```bash
# Format code
make format

# Run quick tests (SPM packages only)
make test-quick

# Run all tests including UI tests
make test

# Build project
make build

# Clean project
make clean

# Development mode with file watching
make dev
```

### Package Management
```bash
# Create new SPM package
make create-package

# Test individual packages
cd Packages/Domain && swift test
cd Packages/Application && swift test
cd Packages/Infrastructure && swift test
```

## Architecture Constraints
- Domain layer has zero external dependencies
- Application layer depends only on Domain
- Infrastructure implements Domain interfaces
- TestSupport provides mocks and fixtures for all layers
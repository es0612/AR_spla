# Project Structure

## Clean Architecture with SPM Packages

The project follows Clean Architecture principles with clear layer separation using Swift Package Manager local packages:

```
ARSplatoonGame/
├── Sources/                    # Main iOS app
│   ├── App/                   # App entry point and root views
│   ├── AR/                    # ARKit integration layer
│   ├── Data/                  # App-level data management
│   └── Views/                 # SwiftUI views and UI components
├── Packages/                  # SPM local packages
│   ├── Domain/               # Business logic (no dependencies)
│   ├── Application/          # Use cases and coordinators
│   ├── Infrastructure/       # External integrations
│   └── TestSupport/          # Shared test utilities
├── Resources/                # App resources and assets
└── Tests/                    # App-level tests
```

## Package Dependencies

```
Domain (pure business logic)
  ↑
Application (use cases, coordinators)
  ↑
Infrastructure (repositories, network, persistence)
  ↑
Main App (UI, AR integration)
```

## Naming Conventions

### Files and Types
- **Entities**: `GameSession.swift`, `Player.swift`, `InkSpot.swift`
- **Value Objects**: `PlayerId.swift`, `Position3D.swift`, `GameScore.swift`
- **Use Cases**: `StartGameUseCase.swift`, `ShootInkUseCase.swift`
- **Repositories**: `GameRepository.swift` (protocol), `InMemoryGameRepository.swift` (implementation)
- **Services**: `ScoreCalculationService.swift`, `GameRuleService.swift`
- **Views**: `MenuView.swift`, `ARGameView.swift`, `GameResultView.swift`

### Test Files
- **Unit Tests**: `[ClassName]Tests.swift`
- **Mock Objects**: `Mock[InterfaceName].swift`
- **Test Builders**: `[EntityName]Builder.swift`
- **Test Fixtures**: `TestData.swift`

## Code Organization

### Domain Package
- `Entities/`: Core business objects
- `ValueObjects/`: Immutable value types with validation
- `Repositories/`: Data access interfaces
- `Services/`: Domain services and business rules

### Application Package
- `UseCases/`: Application-specific business logic
- `Coordinators/`: Orchestrate complex workflows

### Infrastructure Package
- `Persistence/`: Data storage implementations
- `Network/`: Multiplayer communication

### Main App
- `App/`: Application entry point and configuration
- `AR/`: ARKit-specific implementations
- `Data/`: App-level state management (@Observable classes)
- `Views/`: SwiftUI user interface components

## File Headers
All Swift files should include the standard header:
```swift
//
//  [FileName].swift
//  ARSplatoonGame
//
//  Created by [Author] on [Date].
//
```
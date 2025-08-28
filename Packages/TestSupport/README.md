# TestSupport Package

The TestSupport package provides comprehensive testing utilities for the AR Splatoon Game project. It includes builders, mocks, and test fixtures to make testing easier and more consistent across all layers of the application.

## Features

### 🏗️ Test Builders

Fluent builders for creating test instances with sensible defaults:

- **PlayerBuilder**: Create Player instances with customizable properties
- **GameSessionBuilder**: Create GameSession instances with various states
- **InkSpotBuilder**: Create InkSpot instances for testing game mechanics

### 🎭 Mock Repositories

Mock implementations of repository interfaces for testing:

- **MockGameRepository**: Mock implementation of GameRepository
- **MockPlayerRepository**: Mock implementation of PlayerRepository
- **MockRepositoryError**: Common error types for testing error scenarios

### 📊 Test Data & Fixtures

Pre-configured test data for consistent testing:

- **TestData**: Comprehensive collection of test entities and scenarios
- Consistent UUIDs for predictable testing
- Various game scenarios (competitive, one-sided, tie games)
- Random data generators for stress testing

## Usage Examples

### Using Builders

```swift
import TestSupport
import Domain

// Create a simple player
let player = PlayerBuilder()
    .withName("Test Player")
    .withColor(.red)
    .withPosition(x: 1, y: 0, z: 1)
    .build()

// Create a complex game session
let gameSession = GameSessionBuilder()
    .withPlayers([player1, player2])
    .withDuration(180)
    .withStatus(.active)
    .addInkSpot(inkSpot1)
    .addInkSpot(inkSpot2)
    .build()

// Use convenience methods
let redPlayer = PlayerBuilder.redPlayer().build()
let activeGame = GameSessionBuilder.activeGame().build()
```

### Using Mock Repositories

```swift
import TestSupport
import Domain

func testGameService() async throws {
    // Arrange
    let mockRepository = MockGameRepository()
    let gameService = GameService(repository: mockRepository)
    
    // Act
    try await gameService.createGame(players: [player1, player2])
    
    // Assert
    #expect(mockRepository.saveCallCount == 1)
    #expect(mockRepository.lastSavedGameSession != nil)
}

// Test error scenarios
func testErrorHandling() async {
    let mockRepository = MockGameRepository()
    mockRepository.shouldThrowError = true
    mockRepository.errorToThrow = MockRepositoryError.notFound
    
    await #expect(throws: MockRepositoryError.notFound) {
        try await mockRepository.findById(GameSessionId())
    }
}
```

### Using Test Data

```swift
import TestSupport
import Domain

func testGameLogic() {
    // Use pre-configured test data
    let competitiveGame = TestData.competitiveGameScenario()
    let oneSidedGame = TestData.oneSidedGameScenario()
    let tieGame = TestData.tieGameScenario()
    
    // Use standard test entities
    let redPlayer = TestData.redPlayer
    let bluePlayer = TestData.bluePlayer
    let inkSpots = TestData.standardInkSpots
    
    // Generate random data for stress testing
    let randomPlayer = TestData.randomPlayer()
    let randomGame = TestData.randomGameSession()
}
```

## Builder Patterns

All builders follow a consistent fluent interface pattern:

### PlayerBuilder

```swift
PlayerBuilder()
    .withId(PlayerId())
    .withName("Player Name")
    .withColor(.red)
    .withPosition(x: 1, y: 0, z: 1)
    .withScore(paintedArea: 50.0)
    .withActiveStatus(true)
    .build()
```

### GameSessionBuilder

```swift
GameSessionBuilder()
    .withId(GameSessionId())
    .withPlayers([player1, player2])
    .withDuration(180)
    .withStatus(.active)
    .withInkSpots([inkSpot1, inkSpot2])
    .withStartedAt(Date())
    .build()
```

### InkSpotBuilder

```swift
InkSpotBuilder()
    .withId(InkSpotId())
    .withPosition(x: 0, y: 0, z: 0)
    .withColor(.red)
    .withSize(0.5)
    .withOwnerId(playerId)
    .withCreatedAt(Date())
    .build()
```

## Mock Repository Features

### Call Tracking

All mock repositories track method calls:

```swift
let mock = MockGameRepository()
try await mock.save(gameSession)

#expect(mock.saveCallCount == 1)
#expect(mock.lastSavedGameSession?.id == gameSession.id)
```

### Error Simulation

```swift
mock.shouldThrowError = true
mock.errorToThrow = MockRepositoryError.invalidData

// Will throw the specified error
try await mock.save(gameSession)
```

### State Management

```swift
// Pre-populate with test data
mock.prePopulate(with: [gameSession1, gameSession2])

// Check storage state
#expect(mock.storedGameSessionCount == 2)
#expect(mock.contains(gameSession1) == true)

// Reset to clean state
mock.reset()
#expect(mock.storedGameSessionCount == 0)
```

## Test Data Categories

### Standard Entities

- `TestData.redPlayer` / `TestData.bluePlayer`: Standard test players
- `TestData.standardPlayers`: Array of standard players
- `TestData.standardInkSpots`: Array of standard ink spots

### Game Scenarios

- `TestData.competitiveGameScenario()`: Close score game
- `TestData.oneSidedGameScenario()`: Clear winner game
- `TestData.tieGameScenario()`: Tied score game
- `TestData.overlappingInkSpotsScenario()`: Overlapping ink spots

### Random Data

- `TestData.randomPlayer()`: Generate random player
- `TestData.randomInkSpot(ownerId:color:)`: Generate random ink spot
- `TestData.randomGameSession()`: Generate random game session

## Integration with Swift Testing

The TestSupport package is designed to work seamlessly with Swift Testing:

```swift
import Testing
import TestSupport
import Domain

struct GameServiceTests {
    @Test("Game service creates game correctly")
    func testGameCreation() async throws {
        let mockRepository = MockGameRepository()
        let service = GameService(repository: mockRepository)
        
        let players = [TestData.redPlayer, TestData.bluePlayer]
        try await service.createGame(players: players)
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(mockRepository.lastSavedGameSession?.players.count == 2)
    }
}
```

## Best Practices

1. **Use builders for test data creation**: They provide sensible defaults and fluent interfaces
2. **Use TestData for consistent scenarios**: Avoid creating ad-hoc test data
3. **Reset mocks between tests**: Use `mock.reset()` to ensure clean state
4. **Track mock interactions**: Verify that your code calls the expected methods
5. **Test error scenarios**: Use mock error simulation to test error handling
6. **Use random data for stress testing**: Generate varied test data for edge cases

## Dependencies

- **Domain**: Core domain entities and value objects
- **Foundation**: Basic Swift functionality

## Testing

Run the TestSupport tests:

```bash
cd Packages/TestSupport
swift test
```

The package includes comprehensive tests for all builders, mocks, and test data to ensure reliability.
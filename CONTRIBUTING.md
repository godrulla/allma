# Contributing to Allma AI Companion

Thank you for your interest in contributing to Allma! This document provides guidelines and information for contributors.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- **Be respectful**: Treat all community members with respect and kindness
- **Be inclusive**: Welcome people of all backgrounds and experience levels
- **Be collaborative**: Work together constructively and help others learn
- **Be patient**: Remember that everyone was a beginner once
- **Focus on the community**: Keep discussions relevant and productive

## Getting Started

### Prerequisites

- Flutter SDK (3.16.0 or later)
- Dart SDK (3.2.0 or later)
- Git
- A Google Cloud account with Gemini API access

### Development Setup

1. **Fork the repository**
   ```bash
   # Click the "Fork" button on GitHub, then clone your fork
   git clone https://github.com/your-username/allma-ai-companion.git
   cd allma-ai-companion
   ```

2. **Set up development environment**
   ```bash
   # Install dependencies
   flutter pub get
   
   # Set up environment variables
   cp .env.example .env
   # Edit .env with your API keys
   
   # Run the Exxede agents installer
   python3 exxede-agents.py
   ```

3. **Verify setup**
   ```bash
   # Run tests
   flutter test
   
   # Run the app
   flutter run
   ```

## Development Workflow

### Branch Naming

Use descriptive branch names with prefixes:

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test improvements
- `chore/` - Maintenance tasks

Examples:
- `feature/companion-voice-chat`
- `fix/memory-leak-in-chat`
- `docs/update-api-documentation`

### Commit Messages

Follow conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(chat): add voice message support

Implements voice recording and playback functionality
for companion conversations using Flutter sound plugins.

Closes #123
```

```
fix(memory): resolve conversation context overflow

Fixes an issue where long conversations would cause
memory usage to grow unbounded.

Fixes #456
```

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the existing code style and patterns
   - Add tests for new functionality
   - Update documentation as needed
   - Ensure your code passes all linting rules

3. **Test your changes**
   ```bash
   # Run all tests
   flutter test
   
   # Run analyzer
   flutter analyze
   
   # Format code
   dart format lib/ test/
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat(scope): description of changes"
   ```

5. **Push and create a PR**
   ```bash
   git push origin feature/your-feature-name
   # Then create a Pull Request on GitHub
   ```

## Code Style

### Dart/Flutter Guidelines

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format your code
- Prefer composition over inheritance
- Use meaningful variable and function names
- Add documentation comments for public APIs

### Project-Specific Guidelines

1. **File Organization**
   - Group related files in appropriate directories
   - Use lowercase with underscores for file names
   - Keep files focused on a single responsibility

2. **State Management**
   - Use Riverpod for state management
   - Keep providers focused and composable
   - Use appropriate provider types (StateProvider, FutureProvider, etc.)

3. **Error Handling**
   - Use proper exception types
   - Provide meaningful error messages
   - Handle errors gracefully in the UI

4. **Testing**
   - Write unit tests for business logic
   - Write widget tests for UI components
   - Mock external dependencies
   - Aim for good test coverage

### Example Code Style

```dart
// Good: Clear, descriptive names and proper structure
class CompanionConversationService {
  final GeminiService _geminiService;
  final MemoryManager _memoryManager;
  
  CompanionConversationService({
    required GeminiService geminiService,
    required MemoryManager memoryManager,
  }) : _geminiService = geminiService,
       _memoryManager = memoryManager;
  
  /// Generates a response from the companion based on user input
  Future<String> generateResponse({
    required Companion companion,
    required String userMessage,
    required List<Message> conversationHistory,
  }) async {
    try {
      // Implementation here
    } catch (e) {
      throw CompanionException('Failed to generate response: $e');
    }
  }
}
```

## Testing

### Test Types

1. **Unit Tests** - Test individual functions and classes
2. **Widget Tests** - Test UI components in isolation
3. **Integration Tests** - Test complete user flows

### Test Guidelines

- Write tests before or alongside implementation
- Use descriptive test names
- Test both happy path and error cases
- Mock external dependencies
- Keep tests simple and focused

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/companions/companion_test.dart

# Run tests with coverage
flutter test --coverage
```

## Documentation

### Code Documentation

- Add dartdoc comments for all public APIs
- Include usage examples in documentation
- Keep documentation up to date with code changes

```dart
/// Manages conversation memory for AI companions.
/// 
/// The [MemoryManager] stores and retrieves conversation context,
/// enabling companions to maintain consistent personalities and
/// remember past interactions.
/// 
/// Example usage:
/// ```dart
/// final memoryManager = MemoryManager();
/// await memoryManager.storeConversation(companionId, userMessage, response);
/// final memories = await memoryManager.retrieveRelevantMemories(query);
/// ```
class MemoryManager {
  // Implementation
}
```

### Project Documentation

- Update relevant documentation when making changes
- Add new documentation for new features
- Keep the README up to date

## Security Guidelines

### Data Protection

- Never commit API keys or secrets
- Use environment variables for sensitive configuration
- Encrypt all personal data
- Follow privacy-by-design principles

### Code Security

- Validate all user inputs
- Use secure communication (HTTPS)
- Implement proper authentication
- Regular security audits

## Pull Request Process

### Before Submitting

1. Ensure your code passes all tests
2. Update documentation as needed
3. Add appropriate tests for new functionality
4. Follow the code style guidelines
5. Rebase your branch on the latest main

### PR Description Template

```markdown
## Description
Brief description of the changes and their purpose.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Performance improvement

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows the style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or breaking changes documented)

## Related Issues
Closes #123
```

### Review Process

1. **Automated Checks** - CI/CD pipeline runs tests and linting
2. **Code Review** - Maintainers review your code
3. **Feedback** - Address any requested changes
4. **Approval** - Once approved, your PR will be merged

## Community

### Getting Help

- **GitHub Discussions** - Ask questions and discuss ideas
- **Discord** - Real-time chat with the community
- **Issues** - Report bugs or request features

### Recognition

Contributors are recognized in:
- GitHub contributor stats
- Release notes
- Contributors file
- Project documentation

## License

By contributing to Allma, you agree that your contributions will be licensed under the Apache License 2.0.

## Questions?

If you have any questions about contributing, please:

1. Check existing documentation
2. Search previous discussions/issues
3. Ask in GitHub Discussions
4. Contact the maintainers

Thank you for contributing to Allma! Together, we're building the future of AI companions. 🤖❤️
# Allma AI Companion App

An open-source, privacy-preserving AI companion mobile application built with Flutter and Google's Gemini API. Create personalized AI companions with unique personalities for meaningful conversations.

## Features

### 🤖 AI Companions
- **Personalized Personalities**: Create companions with unique traits, backgrounds, and conversation styles
- **Real-time Conversations**: Smooth, responsive chat experience with typing indicators
- **Memory System**: Companions remember past conversations and personal details
- **Multimodal Interaction**: Text, voice, and image support

### 🔒 Privacy & Security
- **End-to-End Encryption**: All conversations encrypted locally
- **Local Storage**: Personal data never leaves your device
- **Anonymous Usage**: No personal information required
- **Open Source**: Full transparency in data handling

### 🎨 User Experience
- **Beautiful Chat Interface**: Smooth animations and intuitive design
- **Companion Builder**: Easy-to-use companion creation wizard
- **Customizable Appearance**: Visual representation of your companions
- **Cross-Platform**: iOS, Android, and web support

### 🛡️ Safety Features
- **Content Moderation**: Built-in safety filters and guidelines
- **Crisis Intervention**: Mental health resources and support
- **Reporting System**: Community-driven safety measures
- **Parental Controls**: Age-appropriate content filtering

## Technology Stack

- **Frontend**: Flutter (Dart)
- **AI Engine**: Google Gemini API
- **State Management**: Riverpod
- **Database**: SQLite with encryption
- **Real-time**: WebSocket connections
- **Image Generation**: Imagen 4 Fast
- **Voice**: Google Text-to-Speech

## Quick Start

### Prerequisites
- Flutter SDK (3.16.0 or later)
- Dart SDK (3.2.0 or later)
- Google Cloud account with Gemini API access
- Android Studio or VS Code

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/exxede/allma-ai-companion.git
cd allma-ai-companion
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure API keys**
```bash
cp .env.example .env
# Edit .env with your Gemini API key
```

4. **Run the app**
```bash
flutter run
```

## Project Structure

```
allma/
├── lib/
│   ├── core/                    # Core business logic
│   │   ├── companions/          # Companion system
│   │   ├── ai/                  # AI integration
│   │   ├── memory/              # Memory management
│   │   └── safety/              # Safety systems
│   ├── features/                # Feature modules
│   │   ├── chat/                # Chat interface
│   │   ├── companion_creation/  # Companion builder
│   │   └── settings/            # User preferences
│   ├── shared/                  # Shared components
│   │   ├── widgets/             # Reusable widgets
│   │   └── utils/               # Helper functions
│   └── main.dart
├── docs/                        # Documentation
├── test/                        # Test files
└── assets/                      # Images and resources
```

## Development

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Code Quality
```bash
# Format code
dart format lib/

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated
```

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Companion System](docs/COMPANION_SYSTEM.md)
- [API Documentation](docs/API_DOCUMENTATION.md)
- [Privacy & Security](docs/PRIVACY_SECURITY.md)
- [Development Guide](docs/DEVELOPMENT_GUIDE.md)
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

### Getting Started
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

## Roadmap

### MVP (v1.0) - Q2 2025
- [x] Basic companion creation
- [x] Real-time chat interface
- [x] Gemini AI integration
- [x] Local data encryption
- [ ] App store deployment

### v1.1 - Q3 2025
- [ ] Voice conversations
- [ ] Image generation
- [ ] Advanced memory system
- [ ] Multi-language support

### v1.2 - Q4 2025
- [ ] Group conversations
- [ ] Companion marketplace
- [ ] Advanced customization
- [ ] Desktop application

## Cost & Scaling

| Users | Monthly Cost | Per User |
|-------|-------------|----------|
| 1K    | $50-100     | $0.05-0.10 |
| 10K   | $200-500    | $0.02-0.05 |
| 100K  | $2K-5K      | $0.02-0.05 |

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/exxede/allma-ai-companion/issues)
- **Discussions**: [GitHub Discussions](https://github.com/exxede/allma-ai-companion/discussions)
- **Discord**: [Join our community](https://discord.gg/allma)
- **Email**: support@exxede.dev

## Acknowledgments

- Google AI for the Gemini API
- Flutter team for the excellent framework
- Open source community for inspiration and contributions

---

**Built with ❤️ by [Exxede](https://exxede.dev) | Founded by Armando Diaz Silverio**
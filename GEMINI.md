# Project Overview: Allma AI Companion App

This project is a comprehensive full-stack application designed to provide an open-source, privacy-preserving AI companion experience. It consists of a Flutter-based mobile application (supporting iOS, Android, and web) and a Node.js/TypeScript backend API.

## Purpose

The primary goal of the Allma AI Companion App is to enable users to create personalized AI companions with unique personalities, engage in real-time conversations, and benefit from a memory system that allows companions to remember past interactions. It emphasizes privacy and security through local encryption and storage, and offers multimodal interaction capabilities (text, voice, image).

## Technology Stack

### Frontend (Mobile Application)

*   **Framework:** Flutter (Dart)
*   **AI Integration:** Google Gemini API (via backend)
*   **State Management:** Riverpod
*   **Database:** SQLite with encryption
*   **Real-time Communication:** WebSocket connections (via `socket_io_client`)
*   **Image Generation:** Imagen 4 Fast (via backend)
*   **Voice:** Google Text-to-Speech, Speech-to-Text, AudioPlayers
*   **Networking:** Dio
*   **Navigation:** GoRouter
*   **Security:** `flutter_secure_storage`, `encrypt`, `crypto`, `local_auth`
*   **Linting:** `flutter_lints`

### Backend (API Server)

*   **Runtime:** Node.js (18+)
*   **Language:** TypeScript
*   **Framework:** Express.js
*   **Authentication & Database:** Firebase (Auth, Firestore)
*   **AI Integration:** Google Gemini API (`@google/generative-ai`)
*   **Real-time Communication:** Socket.io
*   **Validation:** Joi
*   **Logging:** Winston
*   **Security:** Helmet.js, `express-rate-limit`, CORS, bcrypt (password hashing), JSON Web Tokens (JWT)

## Building and Running

### Frontend (Flutter Application)

1.  **Prerequisites:**
    *   Flutter SDK (3.16.0 or later)
    *   Dart SDK (3.2.0 or later)
    *   Google Cloud account with Gemini API access
    *   Android Studio or VS Code
    *   Ensure the backend server is running and accessible.

2.  **Installation:**
    ```bash
    git clone https://github.com/exxede/allma-ai-companion.git
    cd allma-ai-companion
    flutter pub get
    cp .env.example .env
    # Edit .env with your Gemini API key and backend API URL
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

### Backend (Node.js API)

1.  **Prerequisites:**
    *   Node.js 18+
    *   Firebase project with Firestore and Auth enabled
    *   Google Gemini API key

2.  **Installation:**
    ```bash
    cd backend
    npm install
    cp .env.example .env
    # Edit .env with your Firebase and Gemini API configurations
    # Download your Firebase service account key and update .env accordingly
    ```

3.  **Run the development server:**
    ```bash
    npm run dev
    ```

4.  **Build for production:**
    ```bash
    npm run build
    ```

5.  **Start production server:**
    ```bash
    npm start
    ```

## Development Conventions

### Testing

*   **Flutter:**
    *   Unit tests: `flutter test`
    *   Integration tests: `flutter test integration_test/`
    *   Widget tests: `flutter test test/widget_test.dart`
*   **Backend:**
    *   Run all tests: `npm run test`
    *   Run tests in watch mode: `npm run test:watch`
    *   Run tests with coverage: `npm run test:coverage`

### Code Quality

*   **Flutter:**
    *   Format code: `dart format lib/`
    *   Analyze code: `flutter analyze`
    *   Check for outdated packages: `flutter pub outdated`
*   **Backend:**
    *   Run ESLint: `npm run lint`
    *   Run TypeScript check: `npm run typecheck`
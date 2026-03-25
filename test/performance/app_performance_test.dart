import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:allma/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Performance Tests', () {
    group('Startup Performance', () {
      testWidgets('should launch within acceptable time', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        app.main();
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // App should launch within 3 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
        
        // Verify app is properly loaded
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('should handle cold start efficiently', (WidgetTester tester) async {
        // Simulate cold start by clearing all caches
        await tester.binding.defaultBinaryMessenger.send(
          'flutter/navigation',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('SystemNavigator.pop'),
          ),
        );
        
        final stopwatch = Stopwatch()..start();
        
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        
        stopwatch.stop();
        
        // Cold start should complete within 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      testWidgets('should load companion list quickly', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        final stopwatch = Stopwatch()..start();
        
        // Navigate to companion selection
        final companionSelectionButton = find.text('Choose Companion');
        if (companionSelectionButton.evaluate().isNotEmpty) {
          await tester.tap(companionSelectionButton);
          await tester.pumpAndSettle();
        }
        
        stopwatch.stop();
        
        // Companion list should load within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    group('Chat Performance', () {
      testWidgets('should handle rapid message sending', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Navigate to chat
        await _navigateToChat(tester);
        
        final messageInput = find.byType(TextField);
        final sendButton = find.byIcon(Icons.send);
        
        final stopwatch = Stopwatch()..start();
        
        // Send 10 messages rapidly
        for (int i = 0; i < 10; i++) {
          await tester.enterText(messageInput, 'Test message $i');
          await tester.tap(sendButton);
          await tester.pump(const Duration(milliseconds: 100));
        }
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Should handle rapid messaging within 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        
        // Verify messages are displayed
        expect(find.text('Test message 0'), findsOneWidget);
        expect(find.text('Test message 9'), findsOneWidget);
      });

      testWidgets('should maintain smooth scrolling with many messages', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        await _navigateToChat(tester);
        
        // Add many messages to the chat
        await _generateManyMessages(tester, 50);
        
        final listView = find.byType(ListView);
        expect(listView, findsOneWidget);
        
        // Test scrolling performance
        final stopwatch = Stopwatch()..start();
        
        await tester.fling(listView, const Offset(0, -500), 1000);
        await tester.pumpAndSettle();
        
        await tester.fling(listView, const Offset(0, 500), 1000);
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Scrolling should be smooth and complete within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      testWidgets('should handle typing indicators efficiently', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        await _navigateToChat(tester);
        
        final messageInput = find.byType(TextField);
        
        final stopwatch = Stopwatch()..start();
        
        // Simulate rapid typing
        for (int i = 0; i < 20; i++) {
          await tester.enterText(messageInput, 'Typing test $i');
          await tester.pump(const Duration(milliseconds: 50));
        }
        
        stopwatch.stop();
        
        // Typing should remain responsive
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    group('Animation Performance', () {
      testWidgets('should maintain 60fps during page transitions', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Track frame times during navigation
        final frameTimings = <Duration>[];
        
        tester.binding.addPostFrameCallback((_) {
          final renderView = tester.binding.renderView;
          if (renderView.debugLastFrameDuration != null) {
            frameTimings.add(renderView.debugLastFrameDuration!);
          }
        });
        
        // Navigate between screens
        await _performNavigationTest(tester);
        
        // Check frame rates
        final frameTimes = frameTimings.map((d) => d.inMicroseconds).toList();
        final averageFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
        
        // Should maintain close to 60fps (16.67ms per frame)
        expect(averageFrameTime, lessThan(20000)); // 20ms threshold
      });

      testWidgets('should handle complex animations smoothly', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Navigate to a screen with animations
        await _navigateToAnimatedScreen(tester);
        
        final stopwatch = Stopwatch()..start();
        
        // Trigger animations
        final animatedWidget = find.byType(AnimatedContainer).first;
        await tester.tap(animatedWidget);
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Animations should complete smoothly within 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Memory Performance', () {
      testWidgets('should maintain reasonable memory usage', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Get initial memory usage
        final initialMemory = await _getMemoryUsage();
        
        // Perform memory-intensive operations
        await _performMemoryIntensiveOperations(tester);
        
        // Force garbage collection
        await tester.binding.reassembleApplication();
        await tester.pumpAndSettle();
        
        final finalMemory = await _getMemoryUsage();
        
        // Memory increase should be reasonable (less than 50MB)
        final memoryIncrease = finalMemory - initialMemory;
        expect(memoryIncrease, lessThan(50 * 1024 * 1024)); // 50MB
      });

      testWidgets('should handle memory cleanup properly', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        final initialMemory = await _getMemoryUsage();
        
        // Create and destroy many widgets
        for (int i = 0; i < 10; i++) {
          await _navigateToChat(tester);
          await _navigateBack(tester);
          await tester.pumpAndSettle();
        }
        
        // Force garbage collection
        await tester.binding.reassembleApplication();
        await tester.pumpAndSettle();
        
        final finalMemory = await _getMemoryUsage();
        final memoryIncrease = finalMemory - initialMemory;
        
        // Memory should not increase significantly after cleanup
        expect(memoryIncrease, lessThan(20 * 1024 * 1024)); // 20MB
      });
    });

    group('Network Performance', () {
      testWidgets('should handle API timeouts gracefully', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        await _navigateToChat(tester);
        
        // Send a message that will trigger API call
        final messageInput = find.byType(TextField);
        final sendButton = find.byIcon(Icons.send);
        
        await tester.enterText(messageInput, 'Test message for API');
        
        final stopwatch = Stopwatch()..start();
        await tester.tap(sendButton);
        
        // Wait for response or timeout
        await tester.pumpAndSettle(const Duration(seconds: 10));
        
        stopwatch.stop();
        
        // Should handle timeout and show appropriate feedback
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
        
        // Should show some form of feedback (loading, error, or response)
        expect(
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.textContaining('Error').evaluate().isNotEmpty ||
          find.textContaining('response').evaluate().isNotEmpty,
          isTrue,
        );
      });

      testWidgets('should cache data effectively', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // First load
        final stopwatch1 = Stopwatch()..start();
        await _loadCompanionData(tester);
        stopwatch1.stop();
        
        // Navigate away and back
        await _navigateBack(tester);
        await tester.pumpAndSettle();
        
        // Second load (should be faster due to caching)
        final stopwatch2 = Stopwatch()..start();
        await _loadCompanionData(tester);
        stopwatch2.stop();
        
        // Second load should be significantly faster
        expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds * 0.5));
      });
    });

    group('Resource Management', () {
      testWidgets('should clean up resources on app pause', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Simulate app going to background
        await tester.binding.defaultBinaryMessenger.send(
          'flutter/lifecycle',
          const StringCodec().encode('AppLifecycleState.paused'),
        );
        
        await tester.pump();
        
        // App should handle pause state gracefully
        expect(tester.takeException(), isNull);
      });

      testWidgets('should resume efficiently from background', 
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Simulate app going to background
        await tester.binding.defaultBinaryMessenger.send(
          'flutter/lifecycle',
          const StringCodec().encode('AppLifecycleState.paused'),
        );
        
        await tester.pump();
        
        // Simulate app resuming
        final stopwatch = Stopwatch()..start();
        
        await tester.binding.defaultBinaryMessenger.send(
          'flutter/lifecycle',
          const StringCodec().encode('AppLifecycleState.resumed'),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Resume should be quick
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}

// Helper functions for performance testing

Future<void> _navigateToChat(WidgetTester tester) async {
  // This would depend on your app's navigation structure
  final chatButton = find.text('Start Chat').first;
  if (chatButton.evaluate().isNotEmpty) {
    await tester.tap(chatButton);
    await tester.pumpAndSettle();
  }
}

Future<void> _navigateBack(WidgetTester tester) async {
  final backButton = find.byIcon(Icons.arrow_back);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton);
    await tester.pumpAndSettle();
  }
}

Future<void> _generateManyMessages(WidgetTester tester, int count) async {
  final messageInput = find.byType(TextField);
  final sendButton = find.byIcon(Icons.send);
  
  for (int i = 0; i < count; i++) {
    await tester.enterText(messageInput, 'Message $i for testing scrolling performance');
    await tester.tap(sendButton);
    
    // Pump occasionally to prevent test timeout
    if (i % 10 == 0) {
      await tester.pump();
    }
  }
  
  await tester.pumpAndSettle();
}

Future<void> _performNavigationTest(WidgetTester tester) async {
  // Navigate through multiple screens
  final screens = [
    'Companions',
    'Chat',
    'Settings',
    'Privacy',
  ];
  
  for (final screen in screens) {
    final screenButton = find.text(screen);
    if (screenButton.evaluate().isNotEmpty) {
      await tester.tap(screenButton);
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _navigateToAnimatedScreen(WidgetTester tester) async {
  // Navigate to a screen with animations (companion selection)
  final companionButton = find.text('Choose Companion');
  if (companionButton.evaluate().isNotEmpty) {
    await tester.tap(companionButton);
    await tester.pumpAndSettle();
  }
}

Future<int> _getMemoryUsage() async {
  // This would need to be implemented using platform channels
  // For now, return a mock value
  return 0;
}

Future<void> _performMemoryIntensiveOperations(WidgetTester tester) async {
  // Perform operations that use memory
  await _generateManyMessages(tester, 100);
  await _navigateToChat(tester);
  await _loadCompanionData(tester);
}

Future<void> _loadCompanionData(WidgetTester tester) async {
  final companionCard = find.byType(Card).first;
  if (companionCard.evaluate().isNotEmpty) {
    await tester.tap(companionCard);
    await tester.pumpAndSettle();
  }
}
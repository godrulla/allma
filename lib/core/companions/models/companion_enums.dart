/// Enums for companion models to ensure type safety and consistency

/// Companion visual themes
enum CompanionTheme {
  cosmic,
  modern,
  classic,
  minimalist,
  vibrant,
  elegant,
  playful,
  professional,
}

/// Communication styles for companions
enum CommunicationStyle {
  friendly,
  formal,
  casual,
  professional,
  playful,
  supportive,
  analytical,
  creative,
}

/// Personality archetypes
enum PersonalityType {
  innovator,
  helper,
  analyst,
  adventurer,
  caregiver,
  leader,
  artist,
  scholar,
  mentor,
  companion,
}

// Note: Gender and AgeRange are already defined in companion.dart

/// Extensions for better usability
extension CompanionThemeExtension on CompanionTheme {
  String get displayName {
    switch (this) {
      case CompanionTheme.cosmic:
        return 'Cosmic';
      case CompanionTheme.modern:
        return 'Modern';
      case CompanionTheme.classic:
        return 'Classic';
      case CompanionTheme.minimalist:
        return 'Minimalist';
      case CompanionTheme.vibrant:
        return 'Vibrant';
      case CompanionTheme.elegant:
        return 'Elegant';
      case CompanionTheme.playful:
        return 'Playful';
      case CompanionTheme.professional:
        return 'Professional';
    }
  }
}

extension CommunicationStyleExtension on CommunicationStyle {
  String get displayName {
    switch (this) {
      case CommunicationStyle.friendly:
        return 'Friendly';
      case CommunicationStyle.formal:
        return 'Formal';
      case CommunicationStyle.casual:
        return 'Casual';
      case CommunicationStyle.professional:
        return 'Professional';
      case CommunicationStyle.playful:
        return 'Playful';
      case CommunicationStyle.supportive:
        return 'Supportive';
      case CommunicationStyle.analytical:
        return 'Analytical';
      case CommunicationStyle.creative:
        return 'Creative';
    }
  }
}

extension PersonalityTypeExtension on PersonalityType {
  String get displayName {
    switch (this) {
      case PersonalityType.innovator:
        return 'Innovator';
      case PersonalityType.helper:
        return 'Helper';
      case PersonalityType.analyst:
        return 'Analyst';
      case PersonalityType.adventurer:
        return 'Adventurer';
      case PersonalityType.caregiver:
        return 'Caregiver';
      case PersonalityType.leader:
        return 'Leader';
      case PersonalityType.artist:
        return 'Artist';
      case PersonalityType.scholar:
        return 'Scholar';
      case PersonalityType.mentor:
        return 'Mentor';
      case PersonalityType.companion:
        return 'Companion';
    }
  }
}
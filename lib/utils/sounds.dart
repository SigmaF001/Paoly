import 'package:flutter/services.dart';

class AppSounds {
  static Future<void> playSoftClick() async {
    // We can use HapticFeedback for a "tactile" feel
    await HapticFeedback.lightImpact();
    
    // For a soft sound without external assets initially, 
    // we can use SystemSound.
    await SystemSound.play(SystemSoundType.click);
  }
}

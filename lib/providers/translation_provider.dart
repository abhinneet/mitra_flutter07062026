import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// 1. The State Object
class TranslationState {
  final String langCode;
  final bool isDownloading;
  final Map<String, dynamic> strings;

  TranslationState({
    this.langCode = 'en',
    this.isDownloading = false,
    this.strings = const {},
  });

  TranslationState copyWith({
    String? langCode,
    bool? isDownloading,
    Map<String, dynamic>? strings,
  }) {
    return TranslationState(
      langCode: langCode ?? this.langCode,
      isDownloading: isDownloading ?? this.isDownloading,
      strings: strings ?? this.strings,
    );
  }
}

// 2. The Engine (Notifier)
class TranslationNotifier extends StateNotifier<TranslationState> {
  TranslationNotifier() : super(TranslationState()) {
    _loadCachedLanguage();
  }

  // Loads the saved language pack when the app starts
  Future<void> _loadCachedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_lang') ?? 'en';
    final savedStrings = prefs.getString('lang_pack_$savedLang');

    if (savedStrings != null) {
      state = state.copyWith(
        langCode: savedLang,
        strings: json.decode(savedStrings),
      );
    }
  }

  // Triggers the OTA Download
  Future<bool> downloadLanguagePack(String langCode) async {
    // ✨ English and Hindi are hardcoded defaults, no network download needed!
    if (langCode == 'en' || langCode == 'hi') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_lang', langCode);

      // Local dictionary map for Hindi strings
      const localHindiStrings = {
        "select_language_title": "अपनी भाषा चुनें",
        "step_language": "भाषा",
        "step_profile": "प्रोफ़ाइल",
        "step_class": "कक्षा",
        "btn_continue": "आगे बढ़ें →",
        "btn_back": "← पीछे",
        "btn_confirm_class": "कक्षा की पुष्टि करें →"
      };

      state = state.copyWith(
          langCode: langCode,
          strings: langCode == 'hi' ? localHindiStrings : const {},
          isDownloading: false);
      return true;
    }

    // Update UI to show a loading spinner
    state = state.copyWith(isDownloading: true, langCode: langCode);

    try {
      // TODO: Replace with your actual Cloudflare R2 or Backend URL
      final url = 'https://cdn.mitra.in/locales/$langCode.json';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> newStrings = json.decode(response.body);

        // Cache it securely on the phone so it works offline next time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_lang', langCode);
        await prefs.setString('lang_pack_$langCode', response.body);

        // Instantly update the entire App UI
        state = state.copyWith(strings: newStrings, isDownloading: false);
        return true;
      } else {
        throw Exception('Server rejected request');
      }
    } catch (e) {
      debugPrint('Language pack download failed: $e');
      state = state.copyWith(isDownloading: false); // Turn off spinner on fail
      return false;
    }
  }

  // The helper function to translate strings in your UI
  String tr(String key, String fallbackEnglish) {
    return state.strings[key] ?? fallbackEnglish;
  }
}

// 3. The Provider
final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  return TranslationNotifier();
});

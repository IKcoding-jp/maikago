import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maikago/providers/theme_provider.dart';

/// google_fontsの非同期フォント読み込みエラーを抑制してテストを実行する。
/// テスト環境ではHTTPリクエストが400を返すため、google_fontsの非同期操作が
/// 未キャッチ例外としてリークする。runZonedGuardedでこれを捕捉する。
Future<void> withGoogleFontsSuppressed(void Function() body) async {
  final completer = Completer<void>();
  Object? assertionError;
  StackTrace? assertionStack;

  runZonedGuarded(() {
    try {
      body();
    } catch (e, s) {
      // テストのアサーションエラーは保持して後で再スロー
      assertionError = e;
      assertionStack = s;
    }
    // google_fontsの非同期操作が完了/失敗するのを待つ
    Future<void>.delayed(const Duration(milliseconds: 200)).then((_) {
      if (!completer.isCompleted) completer.complete();
    });
  }, (error, stack) {
    // google_fontsのテスト環境エラーを抑制
    if (!completer.isCompleted) completer.complete();
  });

  await completer.future;

  if (assertionError != null) {
    Error.throwWithStackTrace(assertionError!, assertionStack!);
  }
}

/// async bodyを受け取る版
Future<void> withGoogleFontsSuppressedAsync(
  Future<void> Function() body,
) async {
  final completer = Completer<void>();
  Object? assertionError;
  StackTrace? assertionStack;

  runZonedGuarded(() {
    body().then((_) {
      return Future<void>.delayed(const Duration(milliseconds: 200));
    }).then((_) {
      if (!completer.isCompleted) completer.complete();
    }).catchError((Object e, StackTrace s) {
      assertionError = e;
      assertionStack = s;
      if (!completer.isCompleted) completer.complete();
    });
  }, (error, stack) {
    if (!completer.isCompleted) completer.complete();
  });

  await completer.future;

  if (assertionError != null) {
    Error.throwWithStackTrace(assertionError!, assertionStack!);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('初期状態', () {
    test('デフォルトテーマがpinkで初期化される', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        expect(provider.selectedTheme, 'pink');
      });
    });

    test('デフォルトフォントがnunitoで初期化される', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        expect(provider.selectedFont, 'nunito');
      });
    });

    test('デフォルトフォントサイズが16.0で初期化される', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        expect(provider.fontSize, 16.0);
      });
    });

    test('themeDataが非nullで初期化される', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        expect(provider.themeData, isA<ThemeData>());
      });
    });
  });

  group('updateTheme', () {
    test('テーマが更新される', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        provider.updateTheme('blue');
        expect(provider.selectedTheme, 'blue');
      });
    });

    test('テーマ更新でnotifyListenersが呼ばれる', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.updateTheme('green');

        expect(notified, true);
      });
    });

    test('テーマ更新でthemeDataが再構築される', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        final originalThemeData = provider.themeData;

        provider.updateTheme('blue');

        expect(provider.themeData, isNot(same(originalThemeData)));
      });
    });
  });

  group('updateFont', () {
    test('フォントが更新される', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        provider.updateFont('roboto');
        expect(provider.selectedFont, 'roboto');
      });
    });

    test('フォント更新でnotifyListenersが呼ばれる', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.updateFont('roboto');

        expect(notified, true);
      });
    });
  });

  group('updateFontSize', () {
    test('フォントサイズが更新される', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        provider.updateFontSize(20.0);
        expect(provider.fontSize, 20.0);
      });
    });

    test('フォントサイズ更新でnotifyListenersが呼ばれる', () async {
      await withGoogleFontsSuppressed(() {
        final provider = ThemeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.updateFontSize(18.0);

        expect(notified, true);
      });
    });
  });

  group('initFromPersistence', () {
    test('保存済み設定が読み込まれる', () async {
      SharedPreferences.setMockInitialValues({
        'selected_theme': 'blue',
        'selected_font': 'roboto',
        'selected_font_size': 20.0,
      });

      await withGoogleFontsSuppressedAsync(() async {
        final provider = ThemeProvider();
        await provider.initFromPersistence();

        expect(provider.selectedTheme, 'blue');
        expect(provider.selectedFont, 'roboto');
        expect(provider.fontSize, 20.0);
      });
    });

    test('保存値がない場合はデフォルト値が維持される', () async {
      SharedPreferences.setMockInitialValues({});

      await withGoogleFontsSuppressedAsync(() async {
        final provider = ThemeProvider();
        await provider.initFromPersistence();

        expect(provider.selectedTheme, 'pink');
        expect(provider.selectedFont, 'nunito');
        expect(provider.fontSize, 16.0);
      });
    });

    test('initFromPersistenceでnotifyListenersが呼ばれる', () async {
      SharedPreferences.setMockInitialValues({
        'selected_theme': 'green',
      });

      await withGoogleFontsSuppressedAsync(() async {
        final provider = ThemeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.initFromPersistence();

        expect(notified, true);
      });
    });
  });

  group('永続化', () {
    test('updateThemeで設定が保存される', () async {
      SharedPreferences.setMockInitialValues({});

      await withGoogleFontsSuppressedAsync(() async {
        final provider = ThemeProvider();
        provider.updateTheme('blue');

        // SettingsPersistence.saveThemeは非同期のため完了を待つ
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selected_theme'), 'blue');
      });
    });

    test('updateFontで設定が保存される', () async {
      SharedPreferences.setMockInitialValues({});

      await withGoogleFontsSuppressedAsync(() async {
        final provider = ThemeProvider();
        provider.updateFont('roboto');

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selected_font'), 'roboto');
      });
    });

    test('updateFontSizeで設定が保存される', () async {
      SharedPreferences.setMockInitialValues({});

      await withGoogleFontsSuppressedAsync(() async {
        final provider = ThemeProvider();
        provider.updateFontSize(20.0);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('selected_font_size'), 20.0);
      });
    });
  });
}

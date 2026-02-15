# 設計書: Issue #47 ディレクトリ構成の統一

## 変更前後のディレクトリ構成

### Before
```
lib/
├── ad/                              # feature-first (問題)
│   ├── ad_banner.dart
│   ├── app_open_ad_service.dart
│   └── interstitial_ad_service.dart
├── drawer/                          # feature-first (問題)
│   ├── about_screen.dart
│   ├── calculator_screen.dart
│   ├── donation_screen.dart
│   ├── feedback_screen.dart
│   ├── maikago_premium.dart
│   ├── upcoming_features_screen.dart
│   ├── usage_screen.dart
│   └── settings/
│       ├── account_screen.dart
│       ├── advanced_settings_screen.dart
│       ├── privacy_policy_screen.dart
│       ├── settings_font.dart
│       ├── settings_persistence.dart  # ロジック混在
│       ├── settings_screen.dart
│       ├── settings_theme.dart        # ロジック混在
│       └── terms_of_service_screen.dart
├── models/
├── providers/
├── screens/
├── services/
├── utils/
└── widgets/
```

### After
```
lib/
├── models/
├── providers/
├── screens/
│   ├── drawer/                        # drawer/ から移動
│   │   ├── about_screen.dart
│   │   ├── calculator_screen.dart
│   │   ├── donation_screen.dart
│   │   ├── feedback_screen.dart
│   │   ├── maikago_premium.dart
│   │   ├── upcoming_features_screen.dart
│   │   ├── usage_screen.dart
│   │   └── settings/
│   │       ├── account_screen.dart
│   │       ├── advanced_settings_screen.dart
│   │       ├── privacy_policy_screen.dart
│   │       ├── settings_font.dart
│   │       ├── settings_screen.dart
│   │       └── terms_of_service_screen.dart
│   ├── main/
│   └── ...
├── services/
│   ├── ad/                            # ad/ から移動
│   │   ├── ad_banner.dart
│   │   ├── app_open_ad_service.dart
│   │   └── interstitial_ad_service.dart
│   ├── settings_persistence.dart      # drawer/settings/ から移動
│   ├── settings_theme.dart            # drawer/settings/ から移動
│   └── ...
├── utils/
└── widgets/
```

## インポートパス変更マップ

### drawer/ → screens/drawer/
| 旧パス | 新パス |
|--------|--------|
| `maikago/drawer/about_screen.dart` | `maikago/screens/drawer/about_screen.dart` |
| `maikago/drawer/calculator_screen.dart` | `maikago/screens/drawer/calculator_screen.dart` |
| `maikago/drawer/donation_screen.dart` | `maikago/screens/drawer/donation_screen.dart` |
| `maikago/drawer/feedback_screen.dart` | `maikago/screens/drawer/feedback_screen.dart` |
| `maikago/drawer/maikago_premium.dart` | `maikago/screens/drawer/maikago_premium.dart` |
| `maikago/drawer/upcoming_features_screen.dart` | `maikago/screens/drawer/upcoming_features_screen.dart` |
| `maikago/drawer/usage_screen.dart` | `maikago/screens/drawer/usage_screen.dart` |
| `maikago/drawer/settings/account_screen.dart` | `maikago/screens/drawer/settings/account_screen.dart` |
| `maikago/drawer/settings/advanced_settings_screen.dart` | `maikago/screens/drawer/settings/advanced_settings_screen.dart` |
| `maikago/drawer/settings/privacy_policy_screen.dart` | `maikago/screens/drawer/settings/privacy_policy_screen.dart` |
| `maikago/drawer/settings/settings_font.dart` | `maikago/screens/drawer/settings/settings_font.dart` |
| `maikago/drawer/settings/settings_screen.dart` | `maikago/screens/drawer/settings/settings_screen.dart` |
| `maikago/drawer/settings/terms_of_service_screen.dart` | `maikago/screens/drawer/settings/terms_of_service_screen.dart` |

### ロジックファイル → services/
| 旧パス | 新パス |
|--------|--------|
| `maikago/drawer/settings/settings_persistence.dart` | `maikago/services/settings_persistence.dart` |
| `maikago/drawer/settings/settings_theme.dart` | `maikago/services/settings_theme.dart` |

### ad/ → services/ad/
| 旧パス | 新パス |
|--------|--------|
| `maikago/ad/ad_banner.dart` | `maikago/services/ad/ad_banner.dart` |
| `maikago/ad/app_open_ad_service.dart` | `maikago/services/ad/app_open_ad_service.dart` |
| `maikago/ad/interstitial_ad_service.dart` | `maikago/services/ad/interstitial_ad_service.dart` |

## 影響を受けるファイル一覧

### settings_persistence.dart のインポートを持つファイル (11ファイル)
- `lib/providers/repositories/shop_repository.dart`
- `lib/providers/theme_provider.dart`
- `lib/screens/camera_screen.dart`
- `lib/screens/enhanced_camera_screen.dart`
- `lib/screens/main_screen.dart`
- `lib/screens/main/dialogs/budget_dialog.dart`
- `lib/screens/main/dialogs/item_edit_dialog.dart`
- `lib/screens/main/utils/startup_helpers.dart`
- `lib/screens/main/widgets/bottom_summary_widget.dart`
- `lib/services/shop_service.dart`
- `lib/widgets/welcome_dialog.dart`
- + drawer内部ファイル（移動後は screens/drawer/ 内）

### settings_theme.dart のインポートを持つファイル (12ファイル)
- `lib/main.dart`（間接: maikago_premium経由）
- `lib/providers/theme_provider.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/main_screen.dart`
- `lib/screens/release_history_screen.dart`
- `lib/widgets/upgrade_promotion_widget.dart`
- `lib/widgets/version_update_dialog.dart`
- `lib/widgets/welcome_dialog.dart`
- + drawer内部ファイル（移動後は screens/drawer/ 内）

### ad/ のインポートを持つファイル (3ファイル)
- `lib/main.dart`
- `lib/screens/main_screen.dart`
- `lib/screens/main/widgets/bottom_summary_widget.dart`

### drawer/ 画面のインポートを持つファイル
- `lib/main.dart` → `drawer/maikago_premium.dart`
- `lib/screens/main/widgets/main_drawer.dart` → 複数のdrawer画面
- `lib/widgets/upgrade_promotion_widget.dart` → `drawer/maikago_premium.dart`

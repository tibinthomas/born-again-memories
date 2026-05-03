# Graph Report - .  (2026-05-03)

## Corpus Check
- Corpus is ~19,881 words - fits in a single context window. You may not need a graph.

## Summary
- 343 nodes · 369 edges · 32 communities detected
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 62 edges (avg confidence: 0.87)
- Token cost: 1,800 input · 1,200 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Milestone & Profile Features|Milestone & Profile Features]]
- [[_COMMUNITY_Multi-Platform Plugin Registration|Multi-Platform Plugin Registration]]
- [[_COMMUNITY_Build & Platform Config|Build & Platform Config]]
- [[_COMMUNITY_Settings Screen & File Picker|Settings Screen & File Picker]]
- [[_COMMUNITY_Profile & Media Widgets|Profile & Media Widgets]]
- [[_COMMUNITY_Core Data Models|Core Data Models]]
- [[_COMMUNITY_Attachment & File Utilities|Attachment & File Utilities]]
- [[_COMMUNITY_Web & macOS Assets|Web & macOS Assets]]
- [[_COMMUNITY_Android & iOS Icons|Android & iOS Icons]]
- [[_COMMUNITY_Linux Runner & Plugins|Linux Runner & Plugins]]
- [[_COMMUNITY_App Bootstrap & Settings|App Bootstrap & Settings]]
- [[_COMMUNITY_Link Preview & URLs|Link Preview & URLs]]
- [[_COMMUNITY_App Delegates|App Delegates]]
- [[_COMMUNITY_macOS Window Setup|macOS Window Setup]]
- [[_COMMUNITY_Windows Entry Point|Windows Entry Point]]
- [[_COMMUNITY_Test Suite|Test Suite]]
- [[_COMMUNITY_Audio & Chime Utilities|Audio & Chime Utilities]]
- [[_COMMUNITY_Widget Tests|Widget Tests]]
- [[_COMMUNITY_Debug & LLDB Tools|Debug & LLDB Tools]]
- [[_COMMUNITY_iOS Plugin Registrant|iOS Plugin Registrant]]
- [[_COMMUNITY_iOS Scene Delegate|iOS Scene Delegate]]
- [[_COMMUNITY_Android Plugin Registrant|Android Plugin Registrant]]
- [[_COMMUNITY_CocoaPods url_launcher Stub|CocoaPods url_launcher Stub]]
- [[_COMMUNITY_CocoaPods file_selector Stub|CocoaPods file_selector Stub]]
- [[_COMMUNITY_CocoaPods audioplayers Stub|CocoaPods audioplayers Stub]]
- [[_COMMUNITY_CocoaPods Pods Runner Stub|CocoaPods Pods Runner Stub]]
- [[_COMMUNITY_CocoaPods shared_preferences Stub|CocoaPods shared_preferences Stub]]
- [[_COMMUNITY_CocoaPods RunnerTests Stub|CocoaPods RunnerTests Stub]]
- [[_COMMUNITY_Android Main Activity|Android Main Activity]]
- [[_COMMUNITY_Date Formatting Utility|Date Formatting Utility]]
- [[_COMMUNITY_External Link Model|External Link Model]]
- [[_COMMUNITY_Attachment Model|Attachment Model]]

## God Nodes (most connected - your core abstractions)
1. `my_app Flutter Project` - 16 edges
2. `Flutter Default App Icon Design (light blue angular F logo on white background)` - 15 edges
3. `Flutter Logo Design (light blue parallelograms with dark blue accent, origami-style)` - 13 edges
4. `package:flutter/material.dart` - 12 edges
5. `iOS AppIcon Asset Catalog Set` - 11 edges
6. `iOS Platform Target` - 9 edges
7. `AppDelegate` - 8 edges
8. `package:flutter_riverpod/flutter_riverpod.dart` - 6 edges
9. `Create()` - 6 edges
10. `Destroy()` - 6 edges

## Surprising Connections (you probably didn't know these)
- `macOS App Icon (Flutter default)` --references--> `my_app Flutter Project`  [INFERRED]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png → pubspec.yaml
- `Android Launcher Icon hdpi` --semantically_similar_to--> `Flutter Default App Icon Design (light blue angular F logo on white background)`  [INFERRED] [semantically similar]
  android/app/src/main/res/mipmap-hdpi/ic_launcher.png → ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
- `Android Launcher Icon xxxhdpi` --semantically_similar_to--> `Flutter Default App Icon Design (light blue angular F logo on white background)`  [INFERRED] [semantically similar]
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png → ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
- `Android Launcher Icon xxhdpi` --semantically_similar_to--> `Flutter Default App Icon Design (light blue angular F logo on white background)`  [INFERRED] [semantically similar]
  android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png → ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
- `Android Launcher Icon xhdpi` --semantically_similar_to--> `Flutter Default App Icon Design (light blue angular F logo on white background)`  [INFERRED] [semantically similar]
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png → ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png

## Communities

### Community 0 - "Milestone & Profile Features"
Cohesion: 0.05
Nodes (37): dart:async, package:image_picker/image_picker.dart, ../providers/milestone_form_provider.dart, ../providers/profiles_provider.dart, settings_screen.dart, _addLink, _AddMilestoneSheet, _AddMilestoneSheetState (+29 more)

### Community 1 - "Multi-Platform Plugin Registration"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 2 - "Build & Platform Config"
Cohesion: 0.08
Nodes (28): Dart Analysis Options, iOS Launch Image Assets, Linux Flutter CMake Build, Linux CMake Build Configuration (Root), Linux CMake Runner Build, libflutter_linux_gtk.so, GTK+ 3.0 (Linux dependency), macOS App Icon (Flutter default) (+20 more)

### Community 3 - "Settings Screen & File Picker"
Cohesion: 0.09
Nodes (22): package:file_picker/file_picker.dart, package:flutter/services.dart, _aboutTile, _appearanceTile, build, Divider, Expanded, GestureDetector (+14 more)

### Community 4 - "Profile & Media Widgets"
Cohesion: 0.09
Nodes (20): attachment_preview.dart, link_preview_card.dart, ../models/kid_profile.dart, ../models/milestone.dart, addProfile, AddProfileFormNotifier, AddProfileFormState, copyWith (+12 more)

### Community 5 - "Core Data Models"
Cohesion: 0.09
Nodes (17): attachment.dart, external_link.dart, milestone.dart, package:flutter/material.dart, AppSettings, copyWith, KidProfile, Milestone (+9 more)

### Community 6 - "Attachment & File Utilities"
Cohesion: 0.1
Nodes (17): dart:io, ../models/attachment.dart, ../models/external_link.dart, addAttachment, addLink, AddMilestoneFormNotifier, AddMilestoneFormState, copyWith (+9 more)

### Community 7 - "Web & macOS Assets"
Cohesion: 0.18
Nodes (20): macOS App Icon 128x128, macOS App Icon 32x32, Web Favicon, Flutter Framework, Flutter Logo Design (light blue parallelograms with dark blue accent, origami-style), Web PWA Icon 192x192, Web PWA Icon 512x512, iOS App Icon 1024x1024@1x (+12 more)

### Community 8 - "Android & iOS Icons"
Cohesion: 0.2
Nodes (18): Android Mipmap Launcher Icons Group, Flutter Default App Icon Design (light blue angular F logo on white background), Android Launcher Icon hdpi, Android Launcher Icon mdpi, Android Launcher Icon xhdpi, Android Launcher Icon xxhdpi, Android Launcher Icon xxxhdpi, iOS App Icon 20x20@2x (+10 more)

### Community 9 - "Linux Runner & Plugins"
Cohesion: 0.14
Nodes (4): fl_register_plugins(), main(), my_application_activate(), my_application_new()

### Community 10 - "App Bootstrap & Settings"
Cohesion: 0.17
Nodes (10): ../models/app_settings.dart, package:flutter_riverpod/flutter_riverpod.dart, ../providers/app_settings_provider.dart, screens/milestone_home_page.dart, BabyMilestonesApp, build, main, MaterialApp (+2 more)

### Community 11 - "Link Preview & URLs"
Cohesion: 0.17
Nodes (11): package:any_link_preview/any_link_preview.dart, package:url_launcher/url_launcher.dart, AnyLinkPreview, build, _colorForUrl, GestureDetector, _iconForUrl, _LabeledLinkTile (+3 more)

### Community 12 - "App Delegates"
Cohesion: 0.22
Nodes (3): FlutterAppDelegate, FlutterImplicitEngineDelegate, AppDelegate

### Community 13 - "macOS Window Setup"
Cohesion: 0.33
Nodes (3): RegisterGeneratedPlugins(), NSWindow, MainFlutterWindow

### Community 14 - "Windows Entry Point"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 15 - "Test Suite"
Cohesion: 0.4
Nodes (2): RunnerTests, XCTestCase

### Community 16 - "Audio & Chime Utilities"
Cohesion: 0.4
Nodes (4): dart:math, dart:typed_data, package:audioplayers/audioplayers.dart, _buildChimeWav

### Community 17 - "Widget Tests"
Cohesion: 0.5
Nodes (3): package:flutter_test/flutter_test.dart, package:my_app/main.dart, main

### Community 18 - "Debug & LLDB Tools"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 19 - "iOS Plugin Registrant"
Cohesion: 0.67
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 20 - "iOS Scene Delegate"
Cohesion: 0.67
Nodes (2): FlutterSceneDelegate, SceneDelegate

### Community 21 - "Android Plugin Registrant"
Cohesion: 0.67
Nodes (1): GeneratedPluginRegistrant

### Community 22 - "CocoaPods url_launcher Stub"
Cohesion: 1.0
Nodes (1): PodsDummy_url_launcher_macos

### Community 23 - "CocoaPods file_selector Stub"
Cohesion: 1.0
Nodes (1): PodsDummy_file_selector_macos

### Community 24 - "CocoaPods audioplayers Stub"
Cohesion: 1.0
Nodes (1): PodsDummy_audioplayers_darwin

### Community 25 - "CocoaPods Pods Runner Stub"
Cohesion: 1.0
Nodes (1): PodsDummy_Pods_Runner

### Community 26 - "CocoaPods shared_preferences Stub"
Cohesion: 1.0
Nodes (1): PodsDummy_shared_preferences_foundation

### Community 27 - "CocoaPods RunnerTests Stub"
Cohesion: 1.0
Nodes (1): PodsDummy_Pods_RunnerTests

### Community 28 - "Android Main Activity"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 29 - "Date Formatting Utility"
Cohesion: 1.0
Nodes (1): formatDate

### Community 30 - "External Link Model"
Cohesion: 1.0
Nodes (1): ExternalLink

### Community 31 - "Attachment Model"
Cohesion: 1.0
Nodes (1): Attachment

## Knowledge Gaps
- **156 isolated node(s):** `PodsDummy_url_launcher_macos`, `PodsDummy_file_selector_macos`, `PodsDummy_audioplayers_darwin`, `PodsDummy_Pods_Runner`, `PodsDummy_shared_preferences_foundation` (+151 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Test Suite`** (5 nodes): `RunnerTests.swift`, `RunnerTests.swift`, `RunnerTests`, `.testExample()`, `XCTestCase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Debug & LLDB Tools`** (4 nodes): `handle_new_rx_page()`, `__lldb_init_module()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_lldb_helper.py`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `iOS Plugin Registrant`** (3 nodes): `GeneratedPluginRegistrant.m`, `GeneratedPluginRegistrant`, `-registerWithRegistry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `iOS Scene Delegate`** (3 nodes): `FlutterSceneDelegate`, `SceneDelegate.swift`, `SceneDelegate`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android Plugin Registrant`** (3 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant`, `.registerWith()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CocoaPods url_launcher Stub`** (2 nodes): `url_launcher_macos-dummy.m`, `PodsDummy_url_launcher_macos`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CocoaPods file_selector Stub`** (2 nodes): `PodsDummy_file_selector_macos`, `file_selector_macos-dummy.m`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CocoaPods audioplayers Stub`** (2 nodes): `PodsDummy_audioplayers_darwin`, `audioplayers_darwin-dummy.m`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CocoaPods Pods Runner Stub`** (2 nodes): `Pods-Runner-dummy.m`, `PodsDummy_Pods_Runner`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CocoaPods shared_preferences Stub`** (2 nodes): `shared_preferences_foundation-dummy.m`, `PodsDummy_shared_preferences_foundation`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CocoaPods RunnerTests Stub`** (2 nodes): `Pods-RunnerTests-dummy.m`, `PodsDummy_Pods_RunnerTests`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android Main Activity`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Date Formatting Utility`** (2 nodes): `date_formatter.dart`, `formatDate`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `External Link Model`** (2 nodes): `external_link.dart`, `ExternalLink`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Attachment Model`** (2 nodes): `attachment.dart`, `Attachment`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Core Data Models` to `Milestone & Profile Features`, `Settings Screen & File Picker`, `Profile & Media Widgets`, `Attachment & File Utilities`, `App Bootstrap & Settings`, `Link Preview & URLs`?**
  _High betweenness centrality (0.096) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `App Bootstrap & Settings` to `Milestone & Profile Features`, `Settings Screen & File Picker`, `Profile & Media Widgets`, `Attachment & File Utilities`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **Why does `../models/attachment.dart` connect `Attachment & File Utilities` to `Milestone & Profile Features`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `my_app Flutter Project` (e.g. with `macOS App Icon (Flutter default)` and `Flutter Application (README)`) actually correct?**
  _`my_app Flutter Project` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 12 inferred relationships involving `Flutter Default App Icon Design (light blue angular F logo on white background)` (e.g. with `iOS App Icon 20x20@2x` and `iOS App Icon 29x29@3x`) actually correct?**
  _`Flutter Default App Icon Design (light blue angular F logo on white background)` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 13 inferred relationships involving `Flutter Logo Design (light blue parallelograms with dark blue accent, origami-style)` (e.g. with `macOS App Icon 128x128` and `macOS App Icon 32x32`) actually correct?**
  _`Flutter Logo Design (light blue parallelograms with dark blue accent, origami-style)` has 13 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PodsDummy_url_launcher_macos`, `PodsDummy_file_selector_macos`, `PodsDummy_audioplayers_darwin` to the rest of the system?**
  _156 weakly-connected nodes found - possible documentation gaps or missing edges._
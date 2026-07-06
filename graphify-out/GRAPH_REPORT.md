# Graph Report - .  (2026-07-06)

## Corpus Check
- 103 files · ~86,593 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1378 nodes · 1679 edges · 84 communities detected
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 55 edges (avg confidence: 0.76)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Sharing & PDF Export UI|Sharing & PDF Export UI]]
- [[_COMMUNITY_Community Forum & Stories UI|Community Forum & Stories UI]]
- [[_COMMUNITY_Media Capture & Attachments|Media Capture & Attachments]]
- [[_COMMUNITY_Feature Screens Shell|Feature Screens Shell]]
- [[_COMMUNITY_Riverpod Providers Core|Riverpod Providers Core]]
- [[_COMMUNITY_Account & Backup Domain Concepts|Account & Backup Domain Concepts]]
- [[_COMMUNITY_Auth & Account Screens|Auth & Account Screens]]
- [[_COMMUNITY_Milestone Detail UI|Milestone Detail UI]]
- [[_COMMUNITY_Attachments & iCloud Media|Attachments & iCloud Media]]
- [[_COMMUNITY_Data Models|Data Models]]
- [[_COMMUNITY_Add MilestoneProfile Sheets|Add Milestone/Profile Sheets]]
- [[_COMMUNITY_Bubble UI & Drive Backup|Bubble UI & Drive Backup]]
- [[_COMMUNITY_Reminders & Calendar|Reminders & Calendar]]
- [[_COMMUNITY_Saved Links|Saved Links]]
- [[_COMMUNITY_Growth Charts (WHO)|Growth Charts (WHO)]]
- [[_COMMUNITY_Memory Sparks|Memory Sparks]]
- [[_COMMUNITY_Documents Screen|Documents Screen]]
- [[_COMMUNITY_Future Plans|Future Plans]]
- [[_COMMUNITY_App Bootstrap & Firebase|App Bootstrap & Firebase]]
- [[_COMMUNITY_CDC Dev Checklist|CDC Dev Checklist]]
- [[_COMMUNITY_Profile Header & Backup Indicator|Profile Header & Backup Indicator]]
- [[_COMMUNITY_Login UI|Login UI]]
- [[_COMMUNITY_Google Photos Picker (deprecated)|Google Photos Picker (deprecated)]]
- [[_COMMUNITY_Bubble Decoration Widgets|Bubble Decoration Widgets]]
- [[_COMMUNITY_Memory Sharing (Share Sheet)|Memory Sharing (Share Sheet)]]
- [[_COMMUNITY_Native Platform Glue|Native Platform Glue]]
- [[_COMMUNITY_macOS App Delegate|macOS App Delegate]]
- [[_COMMUNITY_Pubspec Dependencies|Pubspec Dependencies]]
- [[_COMMUNITY_Graphify Tooling Docs|Graphify Tooling Docs]]
- [[_COMMUNITY_Settings Card Components|Settings Card Components]]
- [[_COMMUNITY_Account Deletion Flow|Account Deletion Flow]]
- [[_COMMUNITY_Runner Unit Tests|Runner Unit Tests]]
- [[_COMMUNITY_macOS Main Window|macOS Main Window]]
- [[_COMMUNITY_Widget Test|Widget Test]]
- [[_COMMUNITY_Blog Post Model|Blog Post Model]]
- [[_COMMUNITY_Forum Models|Forum Models]]
- [[_COMMUNITY_iOS Scene Delegate|iOS Scene Delegate]]
- [[_COMMUNITY_Date Formatting|Date Formatting]]
- [[_COMMUNITY_Share Invite Model|Share Invite Model]]
- [[_COMMUNITY_Saved Link Model|Saved Link Model]]
- [[_COMMUNITY_Reminder Model|Reminder Model]]
- [[_COMMUNITY_Growth Entry Model|Growth Entry Model]]
- [[_COMMUNITY_Future Plan Model|Future Plan Model]]
- [[_COMMUNITY_Memory Sparks Data|Memory Sparks Data]]
- [[_COMMUNITY_CDC Milestones Data|CDC Milestones Data]]
- [[_COMMUNITY_VideoPhoto Picker (deprecated)|Video/Photo Picker (deprecated)]]
- [[_COMMUNITY_Android MainActivity|Android MainActivity]]
- [[_COMMUNITY_Milestone Templates|Milestone Templates]]
- [[_COMMUNITY_WHO Percentile Data|WHO Percentile Data]]
- [[_COMMUNITY_Profile Theming|Profile Theming]]
- [[_COMMUNITY_Dev Milestone Templates|Dev Milestone Templates]]
- [[_COMMUNITY_CDCWHO Lookup Functions|CDC/WHO Lookup Functions]]
- [[_COMMUNITY_Attachment Type Helpers|Attachment Type Helpers]]
- [[_COMMUNITY_iOS Scene Delegate Glue|iOS Scene Delegate Glue]]
- [[_COMMUNITY_Document Category|Document Category]]
- [[_COMMUNITY_DevTools Options|DevTools Options]]
- [[_COMMUNITY_Analysis Options|Analysis Options]]
- [[_COMMUNITY_WHO Metric Enum|WHO Metric Enum]]
- [[_COMMUNITY_CDC Milestones Table|CDC Milestones Table]]
- [[_COMMUNITY_Dev Domain Enum|Dev Domain Enum]]
- [[_COMMUNITY_Google Photo Item Model|Google Photo Item Model]]
- [[_COMMUNITY_Google Photo Album Model|Google Photo Album Model]]
- [[_COMMUNITY_Backup Permissions Service|Backup Permissions Service]]
- [[_COMMUNITY_Backup Permissions Status|Backup Permissions Status]]
- [[_COMMUNITY_Milestone Notification Trigger|Milestone Notification Trigger]]
- [[_COMMUNITY_PDF Dependency|PDF Dependency]]
- [[_COMMUNITY_Share Plus Dependency|Share Plus Dependency]]
- [[_COMMUNITY_Image Cropper Dependency|Image Cropper Dependency]]
- [[_COMMUNITY_Permission Handler Dependency|Permission Handler Dependency]]
- [[_COMMUNITY_HTTP Dependency|HTTP Dependency]]
- [[_COMMUNITY_Path Provider Dependency|Path Provider Dependency]]
- [[_COMMUNITY_Google Photos Pagination|Google Photos Pagination]]
- [[_COMMUNITY_PDF Export Action|PDF Export Action]]
- [[_COMMUNITY_Story Publish Action|Story Publish Action]]
- [[_COMMUNITY_Forum Answer Submit Action|Forum Answer Submit Action]]
- [[_COMMUNITY_Forum Question Delete Action|Forum Question Delete Action]]
- [[_COMMUNITY_Audio Tile Widget|Audio Tile Widget]]
- [[_COMMUNITY_Document Sheet Widget|Document Sheet Widget]]
- [[_COMMUNITY_Story Like Toggle Action|Story Like Toggle Action]]
- [[_COMMUNITY_Reminder Save Action|Reminder Save Action]]
- [[_COMMUNITY_Shared Feed Load Action|Shared Feed Load Action]]
- [[_COMMUNITY_Gradient FAB Widget|Gradient FAB Widget]]
- [[_COMMUNITY_Overview Chip Widget|Overview Chip Widget]]
- [[_COMMUNITY_Empty State Widget|Empty State Widget]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 52 edges
2. `package:flutter_riverpod/flutter_riverpod.dart` - 31 edges
3. `../utils/profile_theme.dart` - 27 edges
4. `../models/kid_profile.dart` - 24 edges
5. `package:flutter/foundation.dart` - 22 edges
6. `dart:io` - 21 edges
7. `../../../providers/profiles_provider.dart` - 16 edges
8. `AddMilestoneSheet` - 16 edges
9. `../models/attachment.dart` - 14 edges
10. `../models/milestone.dart` - 14 edges

## Surprising Connections (you probably didn't know these)
- `PdfExportService` --references--> `"M 4 Memories" app title`  [EXTRACTED]
  lib/services/pdf_export_service.dart → web/index.html
- `RegisterGeneratedPlugins (macOS plugin registration)` --semantically_similar_to--> `GeneratedPluginRegistrant.register (iOS plugin registration)`  [INFERRED] [semantically similar]
  macos/Runner/MainFlutterWindow.swift → ios/Runner/AppDelegate.swift
- `appAuthRedirectScheme manifest placeholder (OAuth redirect, m4memories.surprise.in)` --semantically_similar_to--> `GIDSignIn (Google Sign-In SDK URL handler)`  [INFERRED] [semantically similar]
  android/app/build.gradle.kts → macos/Runner/AppDelegate.swift
- `RunnerTests (placeholder XCTest class, iOS and macOS)` --conceptually_related_to--> `AppDelegate (native Flutter host, iOS/macOS)`  [AMBIGUOUS]
  ios/RunnerTests/RunnerTests.swift → macos/Runner/AppDelegate.swift
- `_share() (invokes SharePlus)` --references--> `Born Again Memories (BAM) — project concept`  [EXTRACTED]
  lib/utils/memory_sharer.dart → README.md

## Hyperedges (group relationships)
- **Flutter Generated Plugin Registration Across Native Hosts** — appdelegate_appdelegate, mainflutterwindow_mainflutterwindow, generatedpluginregistrant_register, generatedpluginregistrant_registergeneratedplugins [INFERRED 0.85]
- **Android Gradle Build Pipeline for Flutter App** — gradlew_gradlew, settings_gradle_pluginmanagement, build_gradle_rootproject, build_gradle_androidapp [INFERRED 0.90]
- **Native Platform Entry Points Hosting the Flutter Engine** — appdelegate_appdelegate, mainflutterwindow_mainflutterwindow, scenedelegate_scenedelegate, mainactivity_mainactivity [INFERRED 0.85]
- **28-day soft account deletion and recovery** — auth_provider_authservice, main__authedroot, firestore_service_firestoreservice [EXTRACTED 0.95]
- **Shared milestone notification flow (sender invite to recipient push)** — sharing_provider_sharedemailsnotifier, profiles_provider_profilesnotifier, main__authedroot, firestore_service_firestoreservice, notification_service_notificationservice [EXTRACTED 0.95]
- **Attachment cloud backup pipeline (Drive/iCloud)** — backup_provider_backupsyncnotifier, profiles_provider_profilesnotifier, attachment_attachment, drive_service_driveservice, icloud_service_icloudservice, firestore_service_firestoreservice [EXTRACTED 1.00]
- **Child Development & Growth Tracking Data** — milestone_templates_babymilestones, cdc_milestones_cdcmilestones, who_data_whopercentiles [INFERRED 0.70]
- **Memory Export & Sharing Pipeline** — memory_sharer_memorysharer, pdf_export_service_pdfexportservice, attachment_helper_attachmentimagewidget [INFERRED 0.65]
- **Cloud Backup & Push Notification Flow** — google_photos_service_googlephotosservice, backup_permissions_service_backuppermissionsservice, index_onmilestonecreated [INFERRED 0.60]
- **Quick-add-milestone flow shared across home, sparks, and dev checklist screens** — milestone_home_page_milestonehomepage, sparks_screen_sparksscreen, dev_checklist_screen_devchecklistscreen, add_milestone_sheet_addmilestonesheet [INFERRED 0.75]
- **Story publishing flow: browse, write, and read/like a blog post** — stories_screen_storiesscreen, write_story_screen_writestoryscreen, story_detail_screen_storydetailscreen [INFERRED 0.85]
- **Account deletion/recovery lifecycle across settings, recovery, and login screens** — settings_screen_settingsscreen, account_recovery_screen_accountrecoveryscreen, login_screen_loginscreen [INFERRED 0.75]
- **Settings screen cards composed via shared SettingsCard wrapper** — account_card_accountcard, backup_card_backupcard, share_card_sharecard, settings_card_settingscard [EXTRACTED 0.90]
- **Independently duplicated floating-bubble decoration animation** — profile_header_bubble, bubble_layer_bubblelayer, bubble_layer_titlebubblelayer, milestone_card__cardbubble [INFERRED 0.75]
- **Bottom-sheet 'add/select item' UI pattern with drag handle and provider-backed form state** — add_milestone_sheet_addmilestonesheet, add_profile_sheet_addprofilesheet, profile_switcher_sheet_profileswitchersheet [INFERRED 0.70]

## Communities

### Community 0 - "Sharing & PDF Export UI"
Cohesion: 0.02
Nodes (89): ../models/kid_profile.dart, ../models/milestone.dart, package:pdf/pdf.dart, package:pdf/widgets.dart, package:printing/printing.dart, ../services/pdf_export_service.dart, theme_preset.dart, build (+81 more)

### Community 1 - "Community Forum & Stories UI"
Cohesion: 0.02
Nodes (82): forum_detail_screen.dart, ../models/blog_post.dart, ../../../models/share_invite.dart, package:firebase_auth/firebase_auth.dart, ../../../providers/profiles_provider.dart, settings_card.dart, story_detail_screen.dart, _addTag (+74 more)

### Community 2 - "Media Capture & Attachments"
Cohesion: 0.03
Nodes (70): dart:async, dart:io, package:audioplayers/audioplayers.dart, package:camera/camera.dart, package:flutter/foundation.dart, package:flutter/services.dart, package:image_cropper/image_cropper.dart, package:path_provider/path_provider.dart (+62 more)

### Community 3 - "Feature Screens Shell"
Cohesion: 0.03
Nodes (70): dev_checklist_screen.dart, documents_screen.dart, forum_screen.dart, future_plans_screen.dart, growth_screen.dart, home/widgets/add_profile_sheet.dart, home/widgets/theme_preset_picker.dart, milestone_detail_page.dart (+62 more)

### Community 4 - "Riverpod Providers Core"
Cohesion: 0.03
Nodes (65): auth_provider.dart, ../models/app_settings.dart, ../models/baby_document.dart, ../models/forum_question.dart, ../models/future_plan.dart, ../models/growth_entry.dart, ../models/saved_link.dart, ../models/shared_feed.dart (+57 more)

### Community 5 - "Account & Backup Domain Concepts"
Cohesion: 0.04
Nodes (69): _AccountRecoveryScreenState._recover, Attachment (media file with cloud backup IDs), AuthService (Google/Apple sign-in, account deletion), authServiceProvider, BabyDocument, BackupSyncNotifier (Drive/iCloud backup engine), BackupSyncState, BlogPost (+61 more)

### Community 6 - "Auth & Account Screens"
Cohesion: 0.03
Nodes (67): login_screen.dart, milestone_home_page.dart, ../providers/auth_provider.dart, ../services/backup_permissions_service.dart, AccountRecoveryScreen, _AccountRecoveryScreenState, build, _InfoRow (+59 more)

### Community 7 - "Milestone Detail UI"
Cohesion: 0.03
Nodes (59): AnimatedBuilder, AnimatedContainer, _AudioTile, _AudioTileState, _Background, BoxShadow, _BubbleLayer, _BubbleLayerState (+51 more)

### Community 8 - "Attachments & iCloud Media"
Cohesion: 0.03
Nodes (55): ../models/attachment.dart, package:icloud_storage/icloud_storage.dart, package:video_player/video_player.dart, addAttachment, AddMilestoneFormNotifier, AddMilestoneFormState, copyWith, initialize (+47 more)

### Community 9 - "Data Models"
Cohesion: 0.04
Nodes (47): attachment.dart, baby_document.dart, custom_spark.dart, future_plan.dart, growth_entry.dart, kid_profile.dart, milestone.dart, package:flutter/cupertino.dart (+39 more)

### Community 10 - "Add Milestone/Profile Sheets"
Cohesion: 0.05
Nodes (50): _MediaBtn, _RecordingDialog, _SaveBtn, AddMilestoneSheet, AddProfileSheet, AppSettings (feature toggles, theme, menu order), AppSettingsNotifier, appSettingsProvider (+42 more)

### Community 11 - "Bubble UI & Drive Backup"
Cohesion: 0.04
Nodes (46): dart:convert, dart:math, dart:typed_data, package:crypto/crypto.dart, package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart, package:flutter_appauth/flutter_appauth.dart, package:google_sign_in/google_sign_in.dart, package:googleapis/drive/v3.dart (+38 more)

### Community 12 - "Reminders & Calendar"
Cohesion: 0.05
Nodes (42): ../models/reminder.dart, package:device_calendar/device_calendar.dart, package:flutter_local_notifications/flutter_local_notifications.dart, package:googleapis/calendar/v3.dart, package:timezone/data/latest_all.dart, package:timezone/timezone.dart, build, Center (+34 more)

### Community 13 - "Saved Links"
Cohesion: 0.05
Nodes (37): package:any_link_preview/any_link_preview.dart, _addTag, build, _buildPreviewSection, Center, CircularProgressIndicator, _clearAllFilters, Container (+29 more)

### Community 14 - "Growth Charts (WHO)"
Cohesion: 0.06
Nodes (34): ../data/who_data.dart, _ageMonths, build, _ChartPainter, Column, Container, CustomPaint, dispose (+26 more)

### Community 15 - "Memory Sparks"
Cohesion: 0.06
Nodes (31): ../data/memory_sparks.dart, home/widgets/add_milestone_sheet.dart, ../models/custom_spark.dart, copyWith, CustomSpark, _AddCustomSparkSheet, _AddCustomSparkSheetState, build (+23 more)

### Community 16 - "Documents Screen"
Cohesion: 0.06
Nodes (30): package:url_launcher/url_launcher.dart, build, _CategoryChip, Center, Container, Dismissible, dispose, _DocumentCard (+22 more)

### Community 17 - "Future Plans"
Cohesion: 0.06
Nodes (30): _AppBar, build, _CategorySection, Center, _confirmDelete, Container, dispose, _EmptyState (+22 more)

### Community 18 - "App Bootstrap & Firebase"
Cohesion: 0.07
Nodes (28): firebase_options.dart, package:firebase_core/firebase_core.dart, package:firebase_messaging/firebase_messaging.dart, package:flutter_localizations/flutter_localizations.dart, screens/account_recovery_screen.dart, screens/login_screen.dart, screens/milestone_home_page.dart, DefaultFirebaseOptions (+20 more)

### Community 19 - "CDC Dev Checklist"
Cohesion: 0.07
Nodes (28): ../data/cdc_milestones.dart, _ActionSheet, _ActionTile, _AgeGroupCard, build, _Chip, Column, Container (+20 more)

### Community 20 - "Profile Header & Backup Indicator"
Cohesion: 0.07
Nodes (26): ../../../providers/backup_provider.dart, ../../reminders_screen.dart, AnimatedBuilder, AnimatedSwitcher, BackupHeaderIndicator, Bubble, _BubbleState, build (+18 more)

### Community 21 - "Login UI"
Cohesion: 0.08
Nodes (25): AnimatedBuilder, _AppleSignInButton, build, Container, dispose, _FeaturePill, _FloatingBlob, _FloatingBlobState (+17 more)

### Community 22 - "Google Photos Picker (deprecated)"
Cohesion: 0.09
Nodes (22): ../services/google_photos_service.dart, _AlbumChip, build, _buildAlbumBar, _buildGrid, Center, Container, dispose (+14 more)

### Community 23 - "Bubble Decoration Widgets"
Cohesion: 0.09
Nodes (22): BubbleLayer, DetailBubble, TitleBubbleLayer, DevicePerformance, _BrandingPill, _Footer, _GradientCard, _PhotoCard (+14 more)

### Community 24 - "Memory Sharing (Share Sheet)"
Cohesion: 0.1
Nodes (20): dart:ui, package:flutter/rendering.dart, package:share_plus/share_plus.dart, build, Color, Container, dispose, GestureDetector (+12 more)

### Community 25 - "Native Platform Glue"
Cohesion: 0.15
Nodes (14): appAuthRedirectScheme manifest placeholder (OAuth redirect, m4memories.surprise.in), AppDelegate (native Flutter host, iOS/macOS), Android App Module Build Config (m4memories.surprise.in), Android Root Gradle Build Config (relocated build dir, clean task), GeneratedPluginRegistrant.register (iOS plugin registration), RegisterGeneratedPlugins (macOS plugin registration), Google Services Gradle Plugin (Firebase config processing), GIDSignIn (Google Sign-In SDK URL handler) (+6 more)

### Community 26 - "macOS App Delegate"
Cohesion: 0.22
Nodes (3): FlutterAppDelegate, FlutterImplicitEngineDelegate, AppDelegate

### Community 27 - "Pubspec Dependencies"
Cohesion: 0.22
Nodes (9): any_link_preview dependency, audioplayers dependency, file_picker dependency, firebase_auth dependency, flutter_riverpod dependency, google_sign_in dependency, image_picker dependency, url_launcher dependency (+1 more)

### Community 28 - "Graphify Tooling Docs"
Cohesion: 0.46
Nodes (8): Graph Report (graphify-out/GRAPH_REPORT.md), graphify explain command, Graphify Knowledge Graph, graphify-out directory, graphify path command, graphify query command, graphify update command, Wiki Index (graphify-out/wiki/index.md)

### Community 29 - "Settings Card Components"
Cohesion: 0.29
Nodes (7): AccountCard, _fmtBytes, BackupCard, SettingsCard, settingsDivider, InviteRow, ShareCard

### Community 30 - "Account Deletion Flow"
Cohesion: 0.4
Nodes (6): AccountRecoveryScreen, _AccountRecoveryScreenState._deleteNow, LoginScreen, _SettingsScreenState._confirmDeleteAccount, _SettingsScreenState._confirmSignOut, _SettingsScreenState._showFinalDeleteDialog

### Community 31 - "Runner Unit Tests"
Cohesion: 0.4
Nodes (2): RunnerTests, XCTestCase

### Community 32 - "macOS Main Window"
Cohesion: 0.5
Nodes (2): NSWindow, MainFlutterWindow

### Community 33 - "Widget Test"
Cohesion: 0.5
Nodes (3): package:flutter_test/flutter_test.dart, package:my_app/main.dart, main

### Community 34 - "Blog Post Model"
Cohesion: 0.5
Nodes (3): BlogPost, copyWith, isLikedBy

### Community 35 - "Forum Models"
Cohesion: 0.5
Nodes (3): copyWith, ForumAnswer, ForumQuestion

### Community 36 - "iOS Scene Delegate"
Cohesion: 0.67
Nodes (2): FlutterSceneDelegate, SceneDelegate

### Community 37 - "Date Formatting"
Cohesion: 0.67
Nodes (2): formatDate, formatMonthYear

### Community 38 - "Share Invite Model"
Cohesion: 0.67
Nodes (2): copyWith, ShareInvite

### Community 39 - "Saved Link Model"
Cohesion: 0.67
Nodes (2): copyWith, SavedLink

### Community 40 - "Reminder Model"
Cohesion: 0.67
Nodes (2): copyWith, Reminder

### Community 41 - "Growth Entry Model"
Cohesion: 0.67
Nodes (2): copyWith, GrowthEntry

### Community 42 - "Future Plan Model"
Cohesion: 0.67
Nodes (2): copyWith, FuturePlan

### Community 43 - "Memory Sparks Data"
Cohesion: 0.67
Nodes (2): MemorySpark, sparkOfTheDay

### Community 44 - "CDC Milestones Data"
Cohesion: 0.67
Nodes (2): cdcAgeLabel, DevMilestone

### Community 45 - "Video/Photo Picker (deprecated)"
Cohesion: 0.67
Nodes (3): GooglePhotosPicker, _GooglePhotosPickerState._load, VideoRecorderScreen

### Community 46 - "Android MainActivity"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 47 - "Milestone Templates"
Cohesion: 1.0
Nodes (1): MilestoneTemplate

### Community 48 - "WHO Percentile Data"
Cohesion: 1.0
Nodes (1): estimatePercentile

### Community 49 - "Profile Theming"
Cohesion: 1.0
Nodes (2): ProfileTheme, AddProfileFormNotifier

### Community 50 - "Dev Milestone Templates"
Cohesion: 1.0
Nodes (2): DevMilestone, MilestoneTemplate

### Community 51 - "CDC/WHO Lookup Functions"
Cohesion: 1.0
Nodes (1): whoPercentiles() (WHO growth percentile lookup)

### Community 52 - "Attachment Type Helpers"
Cohesion: 1.0
Nodes (1): AttachmentType

### Community 59 - "iOS Scene Delegate Glue"
Cohesion: 1.0
Nodes (1): SceneDelegate (iOS FlutterSceneDelegate subclass)

### Community 60 - "Document Category"
Cohesion: 1.0
Nodes (1): DocumentCategory

### Community 61 - "DevTools Options"
Cohesion: 1.0
Nodes (1): Dart/Flutter DevTools Options (no extensions configured)

### Community 62 - "Analysis Options"
Cohesion: 1.0
Nodes (1): Dart Analysis Options

### Community 67 - "WHO Metric Enum"
Cohesion: 1.0
Nodes (1): WhoMetric (weight/height/head enum)

### Community 68 - "CDC Milestones Table"
Cohesion: 1.0
Nodes (1): cdcMilestones (CDC 'Learn the Signs' table)

### Community 70 - "Dev Domain Enum"
Cohesion: 1.0
Nodes (1): DevDomain enum

### Community 71 - "Google Photo Item Model"
Cohesion: 1.0
Nodes (1): GooglePhotoItem

### Community 72 - "Google Photo Album Model"
Cohesion: 1.0
Nodes (1): GooglePhotoAlbum

### Community 73 - "Backup Permissions Service"
Cohesion: 1.0
Nodes (1): BackupPermissionsService

### Community 74 - "Backup Permissions Status"
Cohesion: 1.0
Nodes (1): BackupPermissionsStatus

### Community 75 - "Milestone Notification Trigger"
Cohesion: 1.0
Nodes (1): onMilestoneCreated (Firestore trigger, push notification fanout)

### Community 76 - "PDF Dependency"
Cohesion: 1.0
Nodes (1): pdf dependency

### Community 77 - "Share Plus Dependency"
Cohesion: 1.0
Nodes (1): share_plus dependency

### Community 78 - "Image Cropper Dependency"
Cohesion: 1.0
Nodes (1): image_cropper dependency

### Community 79 - "Permission Handler Dependency"
Cohesion: 1.0
Nodes (1): permission_handler dependency

### Community 80 - "HTTP Dependency"
Cohesion: 1.0
Nodes (1): http dependency

### Community 81 - "Path Provider Dependency"
Cohesion: 1.0
Nodes (1): path_provider dependency

### Community 82 - "Google Photos Pagination"
Cohesion: 1.0
Nodes (1): _GooglePhotosPickerState._loadMore

### Community 83 - "PDF Export Action"
Cohesion: 1.0
Nodes (1): _PdfExportSheetState._export

### Community 84 - "Story Publish Action"
Cohesion: 1.0
Nodes (1): _WriteStoryScreenState._publish

### Community 85 - "Forum Answer Submit Action"
Cohesion: 1.0
Nodes (1): _ForumDetailScreenState._submitAnswer

### Community 86 - "Forum Question Delete Action"
Cohesion: 1.0
Nodes (1): _ForumDetailScreenState._confirmDeleteQuestion

### Community 87 - "Audio Tile Widget"
Cohesion: 1.0
Nodes (1): _AudioTile

### Community 88 - "Document Sheet Widget"
Cohesion: 1.0
Nodes (1): _DocumentSheet

### Community 89 - "Story Like Toggle Action"
Cohesion: 1.0
Nodes (1): _StoryDetailScreenState._toggleLike

### Community 90 - "Reminder Save Action"
Cohesion: 1.0
Nodes (1): _ReminderSheetState._save

### Community 91 - "Shared Feed Load Action"
Cohesion: 1.0
Nodes (1): _SharedFeedScreenState._load

### Community 92 - "Gradient FAB Widget"
Cohesion: 1.0
Nodes (1): GradientFab

### Community 93 - "Overview Chip Widget"
Cohesion: 1.0
Nodes (1): OverviewChip

### Community 94 - "Empty State Widget"
Cohesion: 1.0
Nodes (1): EmptyState

## Ambiguous Edges - Review These
- `AppDelegate (native Flutter host, iOS/macOS)` → `RunnerTests (placeholder XCTest class, iOS and macOS)`  [AMBIGUOUS]
  ios/RunnerTests/RunnerTests.swift · relation: conceptually_related_to
- `Born Again Memories (BAM) — project concept` → `"M 4 Memories" app title`  [AMBIGUOUS]
  README.md · relation: conceptually_related_to
- `GooglePhotosPicker` → `_GooglePhotosPickerState._load`  [AMBIGUOUS]
  lib/screens/google_photos_picker.dart · relation: references

## Knowledge Gaps
- **1066 isolated node(s):** `main`, `package:flutter_test/flutter_test.dart`, `package:my_app/main.dart`, `MainActivity`, `DefaultFirebaseOptions` (+1061 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Runner Unit Tests`** (5 nodes): `RunnerTests.swift`, `RunnerTests.swift`, `RunnerTests`, `.testExample()`, `XCTestCase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `macOS Main Window`** (4 nodes): `MainFlutterWindow.swift`, `NSWindow`, `MainFlutterWindow`, `.awakeFromNib()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `iOS Scene Delegate`** (3 nodes): `FlutterSceneDelegate`, `SceneDelegate.swift`, `SceneDelegate`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Date Formatting`** (3 nodes): `date_formatter.dart`, `formatDate`, `formatMonthYear`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Share Invite Model`** (3 nodes): `share_invite.dart`, `copyWith`, `ShareInvite`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Saved Link Model`** (3 nodes): `saved_link.dart`, `copyWith`, `SavedLink`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Reminder Model`** (3 nodes): `reminder.dart`, `copyWith`, `Reminder`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Growth Entry Model`** (3 nodes): `growth_entry.dart`, `copyWith`, `GrowthEntry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Future Plan Model`** (3 nodes): `future_plan.dart`, `copyWith`, `FuturePlan`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Memory Sparks Data`** (3 nodes): `memory_sparks.dart`, `MemorySpark`, `sparkOfTheDay`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CDC Milestones Data`** (3 nodes): `cdc_milestones.dart`, `cdcAgeLabel`, `DevMilestone`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android MainActivity`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Milestone Templates`** (2 nodes): `milestone_templates.dart`, `MilestoneTemplate`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `WHO Percentile Data`** (2 nodes): `who_data.dart`, `estimatePercentile`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Profile Theming`** (2 nodes): `ProfileTheme`, `AddProfileFormNotifier`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Dev Milestone Templates`** (2 nodes): `DevMilestone`, `MilestoneTemplate`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CDC/WHO Lookup Functions`** (2 nodes): `cdcByAgeAndDomain()`, `whoPercentiles() (WHO growth percentile lookup)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Attachment Type Helpers`** (2 nodes): `AttachmentType`, `getAttachmentTypeFromExtension()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `iOS Scene Delegate Glue`** (1 nodes): `SceneDelegate (iOS FlutterSceneDelegate subclass)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Document Category`** (1 nodes): `DocumentCategory`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `DevTools Options`** (1 nodes): `Dart/Flutter DevTools Options (no extensions configured)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Analysis Options`** (1 nodes): `Dart Analysis Options`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `WHO Metric Enum`** (1 nodes): `WhoMetric (weight/height/head enum)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CDC Milestones Table`** (1 nodes): `cdcMilestones (CDC 'Learn the Signs' table)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Dev Domain Enum`** (1 nodes): `DevDomain enum`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Google Photo Item Model`** (1 nodes): `GooglePhotoItem`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Google Photo Album Model`** (1 nodes): `GooglePhotoAlbum`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Backup Permissions Service`** (1 nodes): `BackupPermissionsService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Backup Permissions Status`** (1 nodes): `BackupPermissionsStatus`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Milestone Notification Trigger`** (1 nodes): `onMilestoneCreated (Firestore trigger, push notification fanout)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `PDF Dependency`** (1 nodes): `pdf dependency`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Share Plus Dependency`** (1 nodes): `share_plus dependency`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Image Cropper Dependency`** (1 nodes): `image_cropper dependency`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Permission Handler Dependency`** (1 nodes): `permission_handler dependency`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `HTTP Dependency`** (1 nodes): `http dependency`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Path Provider Dependency`** (1 nodes): `path_provider dependency`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Google Photos Pagination`** (1 nodes): `_GooglePhotosPickerState._loadMore`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `PDF Export Action`** (1 nodes): `_PdfExportSheetState._export`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Story Publish Action`** (1 nodes): `_WriteStoryScreenState._publish`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Forum Answer Submit Action`** (1 nodes): `_ForumDetailScreenState._submitAnswer`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Forum Question Delete Action`** (1 nodes): `_ForumDetailScreenState._confirmDeleteQuestion`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Audio Tile Widget`** (1 nodes): `_AudioTile`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Document Sheet Widget`** (1 nodes): `_DocumentSheet`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Story Like Toggle Action`** (1 nodes): `_StoryDetailScreenState._toggleLike`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Reminder Save Action`** (1 nodes): `_ReminderSheetState._save`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Shared Feed Load Action`** (1 nodes): `_SharedFeedScreenState._load`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Gradient FAB Widget`** (1 nodes): `GradientFab`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Overview Chip Widget`** (1 nodes): `OverviewChip`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Empty State Widget`** (1 nodes): `EmptyState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `AppDelegate (native Flutter host, iOS/macOS)` and `RunnerTests (placeholder XCTest class, iOS and macOS)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Born Again Memories (BAM) — project concept` and `"M 4 Memories" app title`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `GooglePhotosPicker` and `_GooglePhotosPickerState._load`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `package:flutter/material.dart` connect `Data Models` to `Sharing & PDF Export UI`, `Community Forum & Stories UI`, `Media Capture & Attachments`, `Feature Screens Shell`, `Riverpod Providers Core`, `Auth & Account Screens`, `Milestone Detail UI`, `Attachments & iCloud Media`, `Bubble UI & Drive Backup`, `Reminders & Calendar`, `Saved Links`, `Growth Charts (WHO)`, `Memory Sparks`, `Documents Screen`, `Future Plans`, `App Bootstrap & Firebase`, `CDC Dev Checklist`, `Profile Header & Backup Indicator`, `Login UI`, `Google Photos Picker (deprecated)`, `Memory Sharing (Share Sheet)`?**
  _High betweenness centrality (0.250) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Riverpod Providers Core` to `Sharing & PDF Export UI`, `Community Forum & Stories UI`, `Media Capture & Attachments`, `Feature Screens Shell`, `Auth & Account Screens`, `Milestone Detail UI`, `Attachments & iCloud Media`, `Bubble UI & Drive Backup`, `Reminders & Calendar`, `Saved Links`, `Growth Charts (WHO)`, `Memory Sparks`, `Documents Screen`, `Future Plans`, `App Bootstrap & Firebase`, `CDC Dev Checklist`, `Profile Header & Backup Indicator`, `Login UI`, `Google Photos Picker (deprecated)`?**
  _High betweenness centrality (0.088) - this node is a cross-community bridge._
- **Why does `../utils/profile_theme.dart` connect `Sharing & PDF Export UI` to `Community Forum & Stories UI`, `Media Capture & Attachments`, `Feature Screens Shell`, `Riverpod Providers Core`, `Auth & Account Screens`, `Milestone Detail UI`, `Attachments & iCloud Media`, `Bubble UI & Drive Backup`, `Reminders & Calendar`, `Saved Links`, `Growth Charts (WHO)`, `Memory Sparks`, `Documents Screen`, `Future Plans`, `CDC Dev Checklist`, `Profile Header & Backup Indicator`, `Memory Sharing (Share Sheet)`?**
  _High betweenness centrality (0.052) - this node is a cross-community bridge._
- **What connects `main`, `package:flutter_test/flutter_test.dart`, `package:my_app/main.dart` to the rest of the system?**
  _1066 weakly-connected nodes found - possible documentation gaps or missing edges._
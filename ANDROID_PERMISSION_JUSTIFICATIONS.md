# Android permission justifications

This document describes the permissions intentionally present in the production
manifest. Permission prompts are shown only when the user starts the related
feature.

| Permission | User-facing purpose | Handling |
| --- | --- | --- |
| `INTERNET` | Authentication, Firebase sync, family sharing, community features, link previews, and optional cloud backup. | Required for connected app features. |
| `CAMERA` | Capture a child profile photo or photo/video attachment for a memory. | Requested only when the user chooses camera capture. The app remains usable if declined. |
| `RECORD_AUDIO` | Record a voice memo or the audio track of an in-app video. | Requested only when recording is started. The app remains usable if declined. |
| `POST_NOTIFICATIONS` | Deliver user-created reminders, shared-memory alerts, and backup status alerts on Android 13+. | Requested in context; users can decline and continue using the app. |
| `READ_CALENDAR` | List writable device calendars and locate an event previously created by Growing Memories. | Used only after the user chooses device-calendar synchronization. |
| `WRITE_CALENDAR` | Create, update, or remove the reminder event the user chose to synchronize. | Used only for an explicit calendar-sync action. |
| `RECEIVE_BOOT_COMPLETED` | Restore locally scheduled reminder notifications after a device restart or app update. | No user data is collected by the boot receiver. |
| `VIBRATE` | Notification vibration and user-enabled haptic feedback. | Controlled by app/device settings. |

## Permissions intentionally excluded

- `USE_EXACT_ALARM`: Growing Memories is not primarily an alarm, timer, or calendar
  app. Reminders use inexact, idle-aware scheduling instead.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: backup is not a qualifying core use
  case for a direct Doze exemption request. The app respects Android power
  management.
- Broad photo/video or external-storage permissions: media selection uses the
  system picker and app-private storage.
- Location, contacts, phone, SMS, call-log, accessibility, installed-app-list,
  and package-management permissions: these are not needed by the app.

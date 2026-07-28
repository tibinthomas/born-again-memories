# Manual Testing Checklist

Use this checklist for release candidates and significant feature changes.
Record defects with steps, screenshots or recordings, device details, and logs.

## Test Run Details

- [ ] Tester:
- [ ] Date:
- [ ] App version/build:
- [ ] Git commit:
- [ ] Build type: debug / profile / release
- [ ] Distribution: local / Firebase / Play Internal Testing
- [ ] Device and model:
- [ ] Android version:
- [ ] Screen size:
- [ ] Network: Wi-Fi / cellular / offline
- [ ] Test account:
- [ ] Existing user or new user:

## Release Smoke Test

- [ ] App installs successfully from the intended release source.
- [ ] App launches without a crash or blank screen.
- [ ] Splash/loading screen displays correctly.
- [ ] Sign-in completes successfully.
- [ ] Existing profiles and memories load.
- [ ] A profile can be created.
- [ ] A memory can be created and reopened.
- [ ] Settings opens.
- [ ] Sign-out works.
- [ ] App relaunches successfully after being force-stopped.
- [ ] No debug banners, developer controls, test data, or internal messages appear.

## Installation and Upgrade

- [ ] Fresh installation works.
- [ ] Upgrade over the previous production build preserves user data.
- [ ] Upgrade with queued or failed backups does not lose attachments.
- [ ] App handles cleared cache without losing cloud data.
- [ ] App handles cleared app data as a fresh installation.
- [ ] Uninstall and reinstall restores expected cloud data after sign-in.
- [ ] Version name and build number are correct.
- [ ] Launcher name, icon, splash screen, and in-app branding are consistent.

## Authentication

### Google Sign-In

- [ ] Google sign-in button is visible when enabled.
- [ ] Sign-in succeeds with a valid account.
- [ ] Cancelling sign-in returns safely to the login screen.
- [ ] Authentication errors show a useful, non-technical message.
- [ ] A previously authenticated session is restored on relaunch.

### Apple Sign-In

- [ ] Apple sign-in is shown only where supported and enabled.
- [ ] Apple sign-in succeeds.
- [ ] Cancelling Apple sign-in is handled safely.
- [ ] Hidden-email Apple accounts work correctly.

### Session Handling

- [ ] Sign-out asks for confirmation.
- [ ] Sign-out removes access to authenticated screens.
- [ ] Expired or revoked credentials return the user to a safe state.
- [ ] Switching accounts does not expose the previous account's data.
- [ ] Offline launch with an existing session behaves predictably.

## Child Profiles

- [ ] Create a profile with valid required information.
- [ ] Required-field validation is clear.
- [ ] Birthday selection and displayed age are correct.
- [ ] Gender selection saves correctly.
- [ ] Add, replace, and remove an avatar.
- [ ] Add, replace, and remove a background photo.
- [ ] Edit name, nickname, birthday, and profile appearance.
- [ ] Switch between multiple profiles.
- [ ] Each profile shows only its own memories and related data.
- [ ] Profile theme and decorative style persist after relaunch.
- [ ] Delete a profile after confirmation.
- [ ] Cancelling profile deletion preserves the profile.
- [ ] Deleting the selected profile chooses a valid remaining profile.
- [ ] Empty-profile onboarding works after the final profile is removed.

## Memories and Milestones

- [ ] Create a memory from a milestone template.
- [ ] Create a custom memory.
- [ ] Save title, description, date, color, and tags.
- [ ] Required-field validation works.
- [ ] Edit a memory and verify changes persist.
- [ ] Mark and unmark a memory as a favorite.
- [ ] Delete a memory after confirmation.
- [ ] Cancelling deletion preserves the memory.
- [ ] Memories are ordered correctly in the timeline.
- [ ] Dates before and after the child's birthday are handled safely.
- [ ] Long titles, descriptions, and tags render without overflow.
- [ ] Unicode, emoji, punctuation, and multiline text save correctly.
- [ ] Rapidly tapping Save does not create duplicate memories.
- [ ] A memory is still present after force-stop and relaunch.

## Media Attachments

### Photos

- [ ] Capture a photo with the camera.
- [ ] Select a photo from the gallery.
- [ ] Crop or edit a selected image.
- [ ] Add multiple photos.
- [ ] Add, edit, or remove attachment labels.
- [ ] Remove a photo before saving.
- [ ] Delete a saved photo attachment.
- [ ] Large images do not freeze or crash the app.
- [ ] Unsupported or corrupt images fail gracefully.

### Google Photos

- [ ] Google Photos access can be granted.
- [ ] Albums and photos load.
- [ ] Pagination or scrolling loads additional photos.
- [ ] Selecting and importing a photo works.
- [ ] Cancelling import makes no changes.
- [ ] Expired authorization is handled.
- [ ] Network failure shows retry or recovery behavior.

### Video

- [ ] Record a video.
- [ ] Select a video from the device.
- [ ] Video preview and playback work.
- [ ] Play, pause, seek, and replay work.
- [ ] Recording cancellation does not create an attachment.
- [ ] Large or unsupported videos fail gracefully.

### Audio

- [ ] Record a voice memo.
- [ ] Stop and save a recording.
- [ ] Cancel a recording.
- [ ] Select an existing audio file.
- [ ] Play, pause, and seek audio.
- [ ] Playback position and duration are correct.
- [ ] Missing local audio shows a useful message.

### Full-Screen Media and Slideshow

- [ ] Open and close the full-screen gallery.
- [ ] Swipe between multiple photos.
- [ ] Photo counter is correct.
- [ ] Orientation or screen resizing does not break the viewer.
- [ ] Start, pause, and stop the slideshow.
- [ ] Slideshow handles mixed photo/video/audio memories safely.

## Search, Filters, and Timeline

- [ ] Search by title.
- [ ] Search by description.
- [ ] Search by tag.
- [ ] Filter by one tag.
- [ ] Filter by multiple tags.
- [ ] Filter by favorites.
- [ ] Filter by age/year where available.
- [ ] Combine search and filters.
- [ ] Clear all filters.
- [ ] Empty search results show a useful state.
- [ ] Search is case-insensitive.
- [ ] Editing or deleting a visible result updates the list immediately.

## PDF Export and Sharing

- [ ] Open PDF export options.
- [ ] Export all memories.
- [ ] Export favorites only.
- [ ] Export with photos.
- [ ] Export without photos.
- [ ] Export handles memories with missing local media.
- [ ] Export handles an empty profile safely.
- [ ] Generated PDF has correct profile details, dates, text, and page layout.
- [ ] Long text and large images do not overlap or clip.
- [ ] Share a memory using the platform share sheet.
- [ ] Cancelling the share sheet returns safely.

## Growth Tracking

- [ ] Add weight, height, and head-circumference measurements.
- [ ] Validate missing, negative, zero, and unrealistic values.
- [ ] Edit a measurement.
- [ ] Delete a measurement.
- [ ] Measurements appear in correct chronological order.
- [ ] Growth charts render with one and multiple entries.
- [ ] CDC/WHO comparisons use the correct age and gender data.
- [ ] Boundary ages and dates do not crash chart calculations.
- [ ] Chart labels remain readable on small screens.

## Development Checklist

- [ ] Checklist shows the correct age group.
- [ ] Development areas and milestones load.
- [ ] Mark and unmark an item as achieved.
- [ ] Progress totals update correctly.
- [ ] Convert an achieved item into a memory.
- [ ] Converted memory contains the expected title and date.
- [ ] Cancelling conversion leaves the checklist state correct.
- [ ] Checklist progress persists after relaunch.

## Memory Sparks

- [ ] Sparks load and can be filtered by category.
- [ ] Create a memory from a Spark.
- [ ] The resulting memory references the original Spark where expected.
- [ ] Add a personal Spark.
- [ ] Validate empty personal Spark fields.
- [ ] Delete a personal Spark.
- [ ] Personal Sparks persist across devices where expected.

## Stories

- [ ] Story list loads.
- [ ] Create a story with title and body.
- [ ] Add and remove story tags.
- [ ] Edit a story.
- [ ] Delete a story.
- [ ] Open a story detail page.
- [ ] Like and unlike a story.
- [ ] Author attribution and timestamps are correct.
- [ ] Only the author sees edit/delete actions.
- [ ] Offline and server-error states are handled.
- [ ] Reporting and blocking work if Stories are enabled for production.

## Parenting Q&A Forum

- [ ] Forum list loads.
- [ ] Ask a question.
- [ ] Validate empty questions.
- [ ] Add and remove tags.
- [ ] Edit a question.
- [ ] Delete a question and its answers.
- [ ] Open question details.
- [ ] Post, edit, and delete an answer.
- [ ] Answer count stays accurate.
- [ ] Only authors see their edit/delete controls.
- [ ] Reporting content and users works.
- [ ] Blocking a user hides or restricts their content as designed.
- [ ] Terms/community-guideline acceptance occurs before posting.
- [ ] Moderation workflow receives submitted reports.
- [ ] Forum kill switch hides every forum entry point.

## Reminders and Calendar

- [ ] Create a reminder with a future date and time.
- [ ] Create each supported reminder type.
- [ ] Edit a reminder.
- [ ] Mark a reminder complete and incomplete.
- [ ] Delete a reminder.
- [ ] All, Upcoming, and Completed filters are correct.
- [ ] Notification fires at the expected time.
- [ ] Tapping a notification opens the expected app state.
- [ ] Reminder survives device reboot.
- [ ] Denying notification permission is handled.
- [ ] Denying exact-alarm access is handled.
- [ ] Time-zone and daylight-saving changes behave correctly.
- [ ] Optional calendar event creation works.
- [ ] Calendar permission denial is handled.
- [ ] Editing/deleting a reminder updates its calendar event.

## Document Storage

- [ ] Add a PDF.
- [ ] Add an image.
- [ ] Add a Word or other supported file.
- [ ] Add notes, date, and category.
- [ ] Open or preview supported files.
- [ ] Unsupported files show a useful message.
- [ ] Mark and unmark a document as favorite.
- [ ] Filter by category and favorites.
- [ ] Delete a document and confirm local/cloud behavior.
- [ ] Missing local files are handled safely.
- [ ] Large files do not freeze or crash the app.

## Saved Links

- [ ] Add a valid HTTP and HTTPS link.
- [ ] Invalid URLs are rejected clearly.
- [ ] Link-preview title, description, and image load.
- [ ] Preview failure does not prevent saving when appropriate.
- [ ] Edit a link.
- [ ] Add and remove tags.
- [ ] Mark and unmark a link as favorite.
- [ ] Search and filter links.
- [ ] Open a link in the browser.
- [ ] Delete a link.
- [ ] Offline link-preview behavior is acceptable.
- [ ] Malformed or malicious-looking URLs do not crash the app.

## Future Plans

- [ ] Create plans for every category and type.
- [ ] Create a plan with and without a target date.
- [ ] Edit a plan.
- [ ] Mark a plan complete where supported.
- [ ] Delete a plan.
- [ ] Plans are grouped and ordered correctly.
- [ ] Past, current, and distant target dates display correctly.
- [ ] Long titles and notes render correctly.

## Family Sharing

- [ ] Invite an existing user by email.
- [ ] Email matching is case-insensitive.
- [ ] Invite a person who does not yet use the app.
- [ ] Cancel the non-user invitation flow.
- [ ] Resend an invitation.
- [ ] Remove sharing access.
- [ ] Invited user can see only intended shared information.
- [ ] Invited user cannot edit owner-only data.
- [ ] Removing access takes effect promptly.
- [ ] Duplicate and invalid invitations are handled.
- [ ] Shared feed loads.
- [ ] Filter shared feed by sender.
- [ ] Shared-memory count/badge is correct.
- [ ] Shared-memory push notification is received.
- [ ] Tapping a shared notification opens a safe app state.
- [ ] Sharing kill switch hides the feed and invitation controls.

## Backup and Restore

### Google Drive

- [ ] Grant Google Drive access.
- [ ] Deny or cancel Drive access.
- [ ] Automatic backup uploads new media.
- [ ] Manual Sync uploads queued media.
- [ ] Failed uploads show an actionable status.
- [ ] Retry successfully uploads failed items.
- [ ] Backup status survives force-stop and relaunch.
- [ ] Switching Drive accounts shows a warning.
- [ ] Confirming account switch re-uploads as designed.
- [ ] Cancelling account switch preserves the original configuration.
- [ ] Restore/download works on a second device.
- [ ] Deleted memories remove their app-owned backups as designed.

### iCloud

- [ ] iCloud availability is detected correctly on supported devices.
- [ ] iCloud access failure is handled.
- [ ] Automatic upload works.
- [ ] Manual Sync and retry work.
- [ ] Restore/download works on another supported device.
- [ ] Non-Apple platforms do not expose iCloud controls.

### Failure Conditions

- [ ] Backup behaves safely while offline.
- [ ] Network loss during upload does not corrupt data.
- [ ] Low-storage conditions show a useful error.
- [ ] Backgrounding and force-stopping during upload preserve retry state.
- [ ] Duplicate sync does not create duplicate backups.
- [ ] Battery-optimization/background restrictions are explained clearly.

## Settings and Personalization

- [ ] Theme color changes immediately and persists.
- [ ] Two-color and three-color profile themes work.
- [ ] Custom settings icon can be added and removed.
- [ ] Sound effects toggle works.
- [ ] Sound volume control works.
- [ ] Haptic toggle works.
- [ ] Animation and bubble toggle works.
- [ ] Low-performance-device effects behave as intended.
- [ ] Feature entries can be hidden and shown.
- [ ] Home menu can be reordered.
- [ ] Hidden features stay hidden after relaunch.
- [ ] Reordering does not lose or duplicate menu entries.
- [ ] Settings remain isolated between user accounts where expected.

## Bundled Feature Visibility Configuration

For each module in `assets/config/feature_visibility.json`:

- [ ] Set the module to `false`, rebuild, and verify its home entry is hidden.
- [ ] Verify related Settings controls are hidden where applicable.
- [ ] Verify there is no alternate visible navigation entry.
- [ ] Verify notifications or badges for the hidden module do not appear.
- [ ] Verify existing data is preserved while the module is hidden.
- [ ] Restore the module to `true`, rebuild, and verify it reappears.
- [ ] Remove a key temporarily and verify it fails open to visible.
- [ ] Use malformed JSON temporarily and verify the app fails open safely.
- [ ] Restore valid production JSON before creating the release artifact.

Production values:

- [ ] Memories:
- [ ] Child Profiles:
- [ ] Growth Tracking:
- [ ] Development Checklist:
- [ ] Memory Sparks:
- [ ] Stories:
- [ ] Parenting Forum:
- [ ] Reminders:
- [ ] Document Storage:
- [ ] Saved Links:
- [ ] Future Plans:
- [ ] Family Sharing:
- [ ] Backup and Sync:
- [ ] Accounts and Privacy:
- [ ] Personalization and Accessibility:

## Account Deletion and Recovery

- [ ] Start account deletion from Settings.
- [ ] Confirmation explains what will happen.
- [ ] Incorrect confirmation text prevents deletion.
- [ ] Choose to keep Google Drive/iCloud backup.
- [ ] Choose to delete Google Drive/iCloud backup.
- [ ] Signing in during the recovery window shows the recovery screen.
- [ ] Recover the account and verify data remains.
- [ ] Delete immediately from the recovery screen.
- [ ] Scheduled deletion date and remaining days are correct.
- [ ] After the retention window, account access is removed.
- [ ] Deleted account data is no longer accessible.
- [ ] Re-authentication-required errors are handled.
- [ ] Account deletion remains available in every production configuration.

## Permissions

Test both Allow and Deny for each applicable permission:

- [ ] Camera
- [ ] Microphone
- [ ] Photos/media picker
- [ ] Notifications
- [ ] Calendar read/write
- [ ] Exact alarms
- [ ] Battery-optimization exemption

For every permission:

- [ ] Permission is requested only when the related action is initiated.
- [ ] The prompt has clear context.
- [ ] Denial does not crash or trap the user.
- [ ] Permanent denial provides a Settings recovery path where needed.
- [ ] The app does not repeatedly pressure the user after denial.
- [ ] Unrelated features remain usable after denial.

## Offline and Error Handling

- [ ] Launch while offline.
- [ ] Create or edit local-capable content while offline.
- [ ] Reconnect and verify synchronization.
- [ ] Lose network during save, upload, and download.
- [ ] Firebase permission errors are handled safely.
- [ ] Firebase service outage does not expose raw stack traces.
- [ ] Slow network shows loading feedback.
- [ ] Empty states provide a clear next action.
- [ ] Retry buttons work and do not duplicate data.
- [ ] Force-stop during important operations and verify recovery.
- [ ] Device low-storage behavior is acceptable.
- [ ] Device date/time changes do not corrupt ordering.

## Security and Privacy

- [ ] One user cannot read another user's private profiles or content.
- [ ] A shared user has read-only access where intended.
- [ ] Signed-out users cannot access authenticated content.
- [ ] Sensitive information is not printed in production logs.
- [ ] Errors do not reveal tokens, file paths, or private user data.
- [ ] Locally stored media is not exposed unintentionally.
- [ ] Notification text does not reveal excessive child information.
- [ ] External links use safe HTTP/HTTPS handling.
- [ ] Firebase rules are tested against owner, invited user, stranger, and signed-out roles.
- [ ] Account switching clears all previous-user state.
- [ ] Privacy policy and Terms links are accessible.
- [ ] Data Safety declarations match actual app behavior.

## Accessibility and UI

- [ ] Screen reader labels are meaningful.
- [ ] Interactive controls are reachable with TalkBack.
- [ ] Focus order is logical.
- [ ] Text remains readable at maximum system font size.
- [ ] Controls meet reasonable touch-target sizes.
- [ ] Color is not the only indicator of state.
- [ ] Text has sufficient contrast.
- [ ] Portrait layout works on small phones.
- [ ] Large phones and tablets do not show excessive stretching or clipping.
- [ ] Keyboard does not cover form controls or Save buttons.
- [ ] Back button and predictive-back behavior are correct.
- [ ] Loading indicators eventually resolve or show an error.

## Performance and Stability

- [ ] Cold start time is acceptable.
- [ ] Scrolling a large memory timeline is smooth.
- [ ] Large galleries remain responsive.
- [ ] Repeated screen navigation does not noticeably increase memory use.
- [ ] Background/foreground transitions are stable.
- [ ] Rapid taps do not cause duplicate navigation or records.
- [ ] No crashes or ANRs occur during the full test run.
- [ ] Battery use is reasonable during backup and idle periods.
- [ ] Network usage is reasonable for photo/video backup.

## Play Store Release Candidate

- [ ] Release build uses the production signing configuration.
- [ ] Release manifest includes Internet permission.
- [ ] App targets the currently required Android API level.
- [ ] `google-services.json` matches the production package and Firebase app.
- [ ] Google OAuth contains Play signing SHA-1 and SHA-256 fingerprints.
- [ ] Restricted permissions are removed or properly justified.
- [ ] Release AAB builds successfully.
- [ ] AAB is uploaded to Play Internal Testing.
- [ ] Install from Play Internal Testing succeeds.
- [ ] Google sign-in works in the Play-signed build.
- [ ] Play pre-launch report has no unresolved critical issues.
- [ ] Privacy policy URL works without authentication.
- [ ] Web account-deletion URL works without installing the app.
- [ ] Data Safety form matches tested behavior.
- [ ] Content rating and target-audience answers are accurate.
- [ ] Store listing name, description, screenshots, and enabled features match.
- [ ] UGC reporting, blocking, terms acceptance, and moderation are operational.
- [ ] Crash reporting and support contact are monitored.

## Final Sign-Off

- [ ] No open blocker or critical defects.
- [ ] High-severity defects have been fixed and retested.
- [ ] Known lower-severity issues are documented and accepted.
- [ ] Regression testing is complete.
- [ ] Product sign-off:
- [ ] Engineering sign-off:
- [ ] Privacy/policy sign-off:
- [ ] Release owner:
- [ ] Approved release version/build:

## Defect Summary

| ID | Severity | Area | Summary | Status |
| --- | --- | --- | --- | --- |
| | | | | |


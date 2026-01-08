# iCloud Integration Setup Guide for DayGlow

## Overview
DayGlow now includes iCloud integration for:
- ✅ **CloudKit sync** - Events, DayEntries, and Templates sync across devices
- ✅ **iCloud Key-Value Storage** - User preferences and onboarding status persist across installs
- ✅ **Automatic backup** - Data survives app deletion and reinstallation

---

## Required: Enable iCloud in Xcode

You **must** enable iCloud capabilities in Xcode for the integration to work. Follow these steps:

### Step 1: Select the DayGlow Target
1. Open `DayGlow.xcodeproj` in Xcode
2. Click on **DayGlow** project in the navigator (blue icon)
3. Select the **DayGlow** target (under TARGETS)
4. Click the **Signing & Capabilities** tab at the top

### Step 2: Add iCloud Capability
1. Click the **"+ Capability"** button (top left)
2. Search for and double-click **"iCloud"**
3. You should now see an "iCloud" section appear

### Step 3: Configure iCloud Services
In the newly added iCloud section, enable these two services:

#### ✅ CloudKit
- Check the **"CloudKit"** checkbox
- A container will automatically be created: `iCloud.com.yourteam.DayGlow`
- If you want a custom container name:
  - Click the "Containers" dropdown
  - Click the "+" button
  - Enter: `iCloud.com.YourTeamID.DayGlow`

#### ✅ Key-value storage
- Check the **"Key-value storage"** checkbox
- This enables `NSUbiquitousKeyValueStore` for preferences

### Step 4: Sign the App
1. Make sure you're signed in with your Apple ID:
   - Xcode → Settings → Accounts
   - Add your Apple Developer account if not present
2. In Signing & Capabilities:
   - Select your **Team** from the dropdown
   - Ensure **"Automatically manage signing"** is checked
   - Xcode will handle provisioning profiles automatically

---

## What's Been Implemented

### 1. CloudKit for SwiftData
**File**: `ModelContainer+Extension.swift:23`

```swift
cloudKitDatabase: .automatic // iCloud sync enabled
```

**What it does:**
- Automatically syncs Events, DayEntries, and Templates to iCloud
- Changes on one device appear on other devices within seconds
- Data persists even if app is deleted and reinstalled
- Handles merge conflicts automatically

### 2. iCloud Key-Value Storage for Preferences
**File**: `UserPreferences.swift`

**What it does:**
- Stores onboarding status, user preferences, and feature tip flags in iCloud
- Syncs to `NSUbiquitousKeyValueStore` (iCloud)
- Also syncs to `UserDefaults` (local) for @AppStorage compatibility
- Listens for changes from other devices via NotificationCenter

**Key features:**
- Dual storage: iCloud + UserDefaults
- Automatic sync when values change
- Handles cross-device updates
- Works with @AppStorage in SwiftUI views

---

## Testing iCloud Sync

### Test 1: Verify iCloud is Working
1. Build and run DayGlow on a device or simulator
2. Make sure you're signed in with an Apple ID (Settings → [Your Name])
3. Create an event or add a highlight
4. Check Xcode console for any iCloud errors

### Test 2: Cross-Device Sync
1. Install DayGlow on two devices (both signed in with same Apple ID)
2. Device A: Create an event
3. Device B: Wait 5-10 seconds, pull to refresh
4. Event should appear on Device B

### Test 3: Persistence Across Installs
1. Complete onboarding and create some events/highlights
2. Delete the app
3. Reinstall the app
4. Sign in with the same Apple ID
5. Data should automatically sync back

---

## Troubleshooting

### "iCloud sync not working"

**Check these:**
1. ✅ Signed in with Apple ID (Settings → [Your Name])
2. ✅ iCloud Drive is enabled (Settings → [Your Name] → iCloud → iCloud Drive)
3. ✅ DayGlow has iCloud permission (Settings → DayGlow → iCloud)
4. ✅ Internet connection is active
5. ✅ Signing & Capabilities in Xcode has iCloud enabled

**Common issues:**
- Simulator: Make sure you're signed in to iCloud in the simulator settings
- Real device: Check that iCloud storage isn't full
- Sync delay: iCloud can take 5-30 seconds to sync initially

### "Build errors about entitlements"

If you see errors like:
```
Provisioning profile doesn't include the iCloud container
```

**Fix:**
1. Go to Signing & Capabilities
2. Click "Automatically manage signing" (uncheck then recheck)
3. Xcode will regenerate the provisioning profile
4. Clean build folder (Cmd + Shift + K)
5. Rebuild

### "Data not syncing between devices"

**Debug steps:**
1. Check console logs for CloudKit errors
2. Verify both devices are signed in with **same Apple ID**
3. Try force-quitting and reopening the app
4. Check Settings → [Your Name] → iCloud → Show All → DayGlow
   - Make sure it's toggled ON

---

## iCloud Data Structure

### CloudKit Database (SwiftData)
Stores in the **private database** (only visible to the user):
- `Event` records
- `DayEntry` records
- `Template` records

### iCloud Key-Value Storage
Stores these keys:
- `hasCompletedOnboarding`
- `wantsSampleData`
- `hasSeenTemplateIntro`
- `hasSeenConflictTip`
- `hasSeenStreakTip`

---

## Development vs Production

### Development (Current)
- Uses development CloudKit container
- Can be reset in CloudKit Dashboard
- Separate from production data

### Production (App Store)
When you submit to the App Store:
1. Create a production CloudKit container
2. Update entitlements to use production container
3. Deploy schema to production in CloudKit Dashboard
4. Test with TestFlight before release

---

## Migration to Custom Backend (Future)

When you're ready to switch to a custom backend:

### Option 1: Keep iCloud + Add Backend
- iCloud for real-time device sync
- Backend for advanced features (web dashboard, collaboration, etc.)

### Option 2: Replace iCloud with Backend
1. Create REST API endpoints
2. Replace SwiftData with URLSession calls
3. Implement custom sync logic
4. Handle offline mode with local cache

The current architecture supports both approaches.

---

## CloudKit Dashboard

Access CloudKit Dashboard to view/debug data:

1. Go to: https://icloud.developer.apple.com
2. Sign in with your Apple Developer account
3. Select your team
4. Click "CloudKit Dashboard"
5. Select the DayGlow container
6. You can:
   - View records
   - Query data
   - Delete test data
   - Monitor API usage

---

## Limits & Quotas

### iCloud Key-Value Storage
- **Max 1 MB** total storage per app
- **Max 1024 keys**
- **Max 1 MB per key**
- Current usage: ~5 keys × 1 byte each = ~5 bytes (well under limit)

### CloudKit
- **Free tier**: Generous limits for most apps
- Public database: 10 GB storage, 2 GB transfer/day
- Private database: 1 GB storage per user
- DayGlow uses private database (user's iCloud quota)

---

## Next Steps

1. ✅ Enable iCloud in Xcode (follow steps above)
2. ✅ Test on a real device (simulators have limited iCloud support)
3. ✅ Create events/highlights and verify sync
4. ✅ Test cross-device sync with 2 devices
5. ✅ Test reinstall persistence
6. Monitor CloudKit Dashboard for any issues

---

## Questions?

- **CloudKit Documentation**: https://developer.apple.com/icloud/cloudkit/
- **NSUbiquitousKeyValueStore**: https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore
- **SwiftData + CloudKit**: https://developer.apple.com/documentation/swiftdata/syncing-data-across-devices

---

## Summary

Your app now has:
- ✅ Automatic iCloud sync for all data
- ✅ Persistence across app reinstalls
- ✅ Cross-device synchronization
- ✅ Zero backend infrastructure needed
- ✅ Free for users (uses their iCloud storage)

**Just enable iCloud in Xcode and you're ready to go!** 🎉

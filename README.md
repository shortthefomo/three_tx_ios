# XRPL Result Codes (iOS)

Standalone iOS app version of the XRPL & Xahau Result Codes viewer.

## Features

- Real-time XRPL and Xahau transaction data display
- Live data (15s refresh) and historical data (Last 100 transactions with 300s refresh)
- Result codes and transaction type analysis
- WidgetKit support for iOS home screen widget
- **Full dark mode support** - automatically adapts to system appearance settings
- Circular progress indicator showing time until next data refresh

## Open in Xcode

1. Open XRPLResultCodes.xcodeproj in Xcode.
2. Select an iOS simulator or a device.
3. Run the app.

## Notes

- Data is pulled directly from XRPL/Xahau WebSocket endpoints.
- No macOS menu bar widget is included in this iOS project.

## Generating App Icons

To regenerate the app icons, run:

```bash
python3 generate_icons.py
```

This script generates all required iOS app icon sizes (18 total) based on the design in `generate_icons.py`. Icons are saved to `XRPLResultCodes/Assets.xcassets/AppIcon.appiconset/`.

**Requirements:**
- Python 3
- Pillow library: `pip3 install Pillow`

The icon design features a dark background with colorful geometric shapes (green triangles, blue/purple/pink circles - both filled and hollow) arranged in a 3x3 grid pattern.

## Privacy Compliance

This app includes Privacy Manifests (`PrivacyInfo.xcprivacy`) in both the main app and widget targets to comply with Apple's privacy requirements:

- **UserDefaults API**: Used for caching XRPL data across app and widget (App Group)
- **Reason Code**: CA92.1 (App or third-party code does NOT track users)

**If PrivacyInfo.xcprivacy files are not appearing in Xcode:**

1. Open `XRPLResultCodes.xcodeproj` in Xcode
2. Select the **XRPLResultCodes** target
3. Go to **Build Phases** → **Copy Bundle Resources**
4. Click **+** and add `XRPLResultCodes/PrivacyInfo.xcprivacy`
5. Select the **XRPLResultCodesWidget** target
6. Repeat steps 3-4 and add `XRPLResultCodesWidget/PrivacyInfo.xcprivacy`


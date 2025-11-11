# CapacitorWatchEnhanced

**Enhanced Capacitor Watch Plugin with Full Bidirectional Messaging**

> Forked from [@capacitor/watch](https://github.com/ionic-team/CapacitorWatch) with added support for Watch → Phone communication

---

## 🎯 What's New in v1.0.0

This fork adds **full bidirectional messaging** between iPhone and Apple Watch:

✅ **NEW:** Watch → Phone event listeners in JavaScript
✅ **NEW:** `messageReceived` event for incoming watch messages
✅ **NEW:** `messageReceivedWithReply` for interactive request/response patterns
✅ **NEW:** Standard WatchConnectivity methods: `sendMessage()`, `updateApplicationContext()`, `transferUserInfo()`
✅ **NEW:** `getInfo()` method to check watch pairing and reachability status
✅ **NEW:** `reachabilityChanged` listener for connection status monitoring
✅ **100% Backward Compatible** - All existing `@capacitor/watch` code still works

### Why This Fork?

The original `@capacitor/watch` plugin only supports **Phone → Watch** communication. It has no way for JavaScript to receive messages from the watch. This fork adds the missing WCSessionDelegate event forwarding to enable true bidirectional communication.

**Perfect for:**
- Interactive watch apps that need to request data from the phone
- Apps that need to know when watch becomes reachable/unreachable
- Request/response patterns with reply handlers
- Real-time watch-to-phone notifications

---

## 📚 Documentation

- **[ENHANCEMENTS.md](./ENHANCEMENTS.md)** - Complete API reference and examples
- **[VETDRUGS_INTEGRATION.md](./VETDRUGS_INTEGRATION.md)** - VetDrugs-specific integration guide
- **README.md (below)** - Original installation and setup guide

---

## 🚀 Quick Start

### Installation

```bash
# Clone and build
git clone https://github.com/macsupport/CapacitorWatchEnhanced.git
cd CapacitorWatchEnhanced/packages/capacitor-plugin
pnpm install
pnpm run build

# Install in your app
cd /path/to/your/capacitor/app
npm install file:///path/to/CapacitorWatchEnhanced/packages/capacitor-plugin
npx cap sync ios
```

### Basic Usage

```typescript
import { Watch } from '@vetcalculators/capacitor-watch';

// Check if watch is available
const info = await Watch.getInfo();
if (info.isSupported && info.isPaired && info.isWatchAppInstalled) {
  console.log('✅ Watch is ready!');
}

// Listen for messages from watch
Watch.addListener('messageReceived', (message) => {
  console.log('Received from watch:', message);

  if (message.type === 'requestData') {
    // Handle watch request
    handleWatchRequest(message.payload);
  }
});

// Send data to watch
await Watch.updateApplicationContext({
  data: {
    currentState: 'updated',
    timestamp: Date.now()
  }
});
```

---

## 🔄 Migration from @capacitor/watch

**Zero breaking changes!** Just update your import:

```diff
- import { Watch } from '@capacitor/watch';
+ import { Watch } from '@vetcalculators/capacitor-watch';
```

All existing methods (`updateWatchUI`, `updateWatchData`, `runCommand` listener) work exactly the same.

---

## 📦 What's Included

### Outbound Methods (Phone → Watch)
- `updateWatchUI()` - Legacy UI definition (backward compatible)
- `updateWatchData()` - Legacy data updates (backward compatible)
- `sendMessage()` - Interactive messaging with reply handlers **[NEW]**
- `updateApplicationContext()` - Latest-value-only sync **[NEW]**
- `transferUserInfo()` - Queued background transfers **[NEW]**
- `getInfo()` - Check watch status **[NEW]**

### Inbound Events (Watch → Phone)
- `messageReceived` - Simple messages from watch **[NEW]**
- `messageReceivedWithReply` - Messages expecting reply **[NEW]**
- `applicationContextReceived` - Context updates from watch **[NEW]**
- `userInfoReceived` - Background transfers from watch **[NEW]**
- `reachabilityChanged` - Watch connection status **[NEW]**
- `activationStateChanged` - Session state changes **[NEW]**
- `runCommand` - Legacy command listener (backward compatible)

---

## 🛠️ Technical Implementation

### Architecture Changes

1. **CapWatchDelegate.swift** - Enhanced with `notifyListeners()` calls to forward all WCSessionDelegate events to JavaScript
2. **WatchPlugin.swift** - Added new plugin methods and reply handler dictionary
3. **WatchPlugin.m** - Updated Objective-C bridge with new method registrations
4. **definitions.ts** - Complete TypeScript definitions with JSDoc
5. **Weak Reference Pattern** - Plugin → Delegate → Plugin to prevent retain cycles

### Thread Safety
- All delegate callbacks forwarded to JavaScript on main thread
- Reply handlers stored in thread-safe dictionary
- Automatic cleanup after reply sent

---

## 📱 Platform Support

- ✅ **iOS** - Full support (iOS 14+)
- ✅ **watchOS** - Full support (watchOS 7+)
- ⚠️ **Web** - Stubs only (returns "not supported")
- ❌ **Android** - Not supported (no WatchConnectivity on Android)

---

## 🤝 Contributing

Found a bug or want to add features?
1. Open an issue: https://github.com/macsupport/CapacitorWatchEnhanced/issues
2. Submit a PR with tests
3. Update documentation

---

## 📄 License

MIT (same as original @capacitor/watch)

---

## 🙏 Credits

- **Enhanced by:** VetCalculators / @macsupport
- **Original plugin:** Ionic Team - [@capacitor/watch](https://github.com/ionic-team/CapacitorWatch)
- **Use case:** VetDrugs veterinary drug calculator with Apple Watch support

---

# Original @capacitor/watch Documentation

Below is the original setup guide from the Ionic Team's @capacitor/watch plugin.

---

_CapacitorLABS_ - This project is experimental. Support is not provided. Please open issues when needed.

---

The Capacitor Watch plugin allows you to define a UI for a watch in your web code and show it on a paired watch.

This currently only supports iOS. This guide assumes you've already added iOS to your capcacitor project.

Also note - all of this will only work with an actual Apple Watch. Simulators don't allow the app<->watch communcation like real devices do.

## Install

Step 1

Add the watch plugin to your capacitor project, and then open the Xcode project:

```bash
npm install @capacitor/watch
npx cap sync
npx cap open ios
```

Step 2

Go to add capabilities:

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/add-capability.png" />

Add the 'Background Modes' and 'Push Notification' capabilities. Then in the Background Modes options, select 'Background Fetch', 'Remote Notifications', and 'Background Processing'. Your App target should look like this:

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/capabilities-final.png" />

Step 3

Open `AppDelegate.swift` and add `import WatchConnectivity`  and `import CapactiorWatch` to the top of the file, and the following code inside the `application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)` method:

```swift
assert(WCSession.isSupported(), "This sample requires Watch Connectivity support!")
WCSession.default.delegate = CapWatchSessionDelegate.shared
WCSession.default.activate()
```

Step 4

Select File -> New -> Target in Xcode, and then the watchOS tab, and 'App':

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/target-watch.png" />

Click 'Next' then fill out the options like so:

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/watch-target-options.png" />

This dialog can be a little confusing, the key thing is your 'Bundle Identifier' must be `[your apps bundle ID].watchapp` for the watch<->app pairing to work. You must also pick SwiftUI for the Interface and Swift for the language. The project should be `App`.

Step 5

We're going to add the code that makes Capacitor Watch work in the watch application.

---

If you are using <b>Xcode 15 or beyond</b> you then need to add the Capacitor Watch Swift Package from your node_modules:

First go to the project package dependancies

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/spm-project-dependancies.png" />

Then choose 'Add Local'

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/spm-add-local.png" />

Then navigate into the `node_modules/@capacitor/watch/CapWatch-Watch-SPM` folder and click 'Add Package'

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/spm-nav-to-package.png" />

Then in the column on the right pick your watch app to be the target and click 'Add Package'

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/spm-pick-target.png" />

Once this is done your Package Dependancies should look like this:

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/spm-finished.png" />

---

With <b>Xcode 14</b> you will need to go here https://github.com/ionic-team/CapacitorWatch/tree/main/packages/iOS-capWatch-watch/Sources/iOS-capWatch-watch and copy all the files into your Watch project and make sure the target selected is your watch app. It should look like so:

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/watch-sources-added.png" />

Step 6

Then open the watch app's 'Main' file which should be `watchappApp.swift`. Add the lines `import WatchConnectivity` and `import iOS_capWatch_watch`  above the `@main` statement. Then replace the line that says `ContentView()` with this:

The finished file should look like this:

```swift
import SwiftUI
import WatchConnectivity
import iOS_capWatch_watch

@main
struct watchddgg_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            CapWatchContentView()
                .onAppear {
                    assert(WCSession.isSupported(), "This sample requires Watch Connectivity support!")
                    WCSession.default.delegate = WatchViewModel.shared
                    WCSession.default.activate()
                }
        }
    }
}
```

Step 7

Add the 'Background Modes' capability to the watch app target, and enable 'Remote Notifications':

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/watch-remote-not.png" />

You should be ready to develop for Capcacitor Watch now!

## Development workflow

You can still develop your iOS app like a normal capacitor app, but getting things to run on the watch requires you to change the target and destination in Xcode. You can change this with the 'Target Dropdown' near the center-top of Xcode:

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/target-dropdown.png" />

The right half of this bar lets you pick the destination device or simulator. You will need to pick the watch paired with the phone and then hit the 'Run' button or use the 'cmd+r' run shortcut.

There can be some challenges in syncing the watch and phone apps. Sometimes you will get an error in the xcode console complaining the compainion app is not present. The best solution in this case is to re-build and re-install the apps on both devices.

## Building the watch UI and sending it to the watch

You will use a long string to define the watch UI. A newline delimits components. Currently this plugin only supports a vertical scroll view of either Text or Button components.

Once you've defined your UI you can send it to the watch using the `updateWatchUI()` method:

```typescript
async uploadMyWatchUI() {
    const watchUI = 
        `Text("Capacitor WATCH")
         Button("Add One", "inc")`;

    await Watch.updateWatchUI({"watchUI": watchUI});
}
```

Will produce this:

<img src="https://raw.githubusercontent.com/ionic-team/CapacitorWatch/main/img/example-watchui.png" />

## Communicating with the watch

This article provides a great summary on the native methods and their implications: https://alexanderweiss.dev/blog/2023-01-18-three-ways-to-communicate-via-watchconnectivity

On the phone side, you can implement these methods using the Capacitor Background Runner Plugin (https://github.com/ionic-team/capacitor-background-runner). Currently the watch plugin will mainly handle the `didReceiveUserInfo` method, and you can recieve envents from the watch while your app is in the background using the following code in your runner.js:

```javascript
addEventListener("WatchConnectivity_didReceiveUserInfo", (args) => {
  console.log(args.message.jsCommand);
})
```

You can also implment the `runCommand` event listener for foreground procesing:

```typescript
Watch.addListener("runCommand", (data: {command: string}) => {
  console.log("PHONE got command - " + data.command);
})
```

The commands are the 2nd paramter in the `Button()` definition of the watch UI. This can be any string.

## Updating watch data

You can add variables to `Text()` elements by using a `$` variable and updating with the `updateWatchData` command:

```
Text("Show my $number")
```

This example will update `$number` when executed: 

```typescript
var stateData = {
  number: 0
}

async function counterIncrement() {
  stateData.counter++  
  await Watch.updateWatchData({"data": convertValuesOfObjectToStringValues(stateData)})
}
```

# Persistance on the Watch

Capacitor Watch will persist the last UI you sent with `updateWatchUI()`. State from `updateWatchData()` is NOT preserved.


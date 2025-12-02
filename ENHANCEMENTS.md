# CapacitorWatchEnhanced - Bidirectional Messaging Guide

## What's New in v1.0.0

This fork of `@capacitor/watch` adds **full bidirectional messaging** between your iPhone app and Apple Watch, enabling Watch → Phone communication that was missing in the original plugin.

### Key Enhancements

✅ **NEW Event Listeners** - JavaScript can now receive messages from the watch
✅ **Reply Handler Support** - Interactive request/response patterns
✅ **Standard WatchConnectivity Methods** - sendMessage(), updateApplicationContext(), transferUserInfo()
✅ **Connection Status** - getInfo() to check watch pairing and reachability
✅ **Backward Compatible** - All existing `@capacitor/watch` code still works

---

## Installation

```bash
cd /path/to/CapacitorWatchEnhanced/packages/capacitor-plugin
pnpm install
pnpm run build
```

Then in your Capacitor app:

```bash
npm install file:///path/to/CapacitorWatchEnhanced/packages/capacitor-plugin
npx cap sync ios
```

---

## Breaking Changes from @capacitor/watch

**None!** This plugin is 100% backward compatible. Existing code using `updateWatchUI()`, `updateWatchData()`, and the `runCommand` listener will continue to work.

---

## New API Reference

### Outbound Methods (Phone → Watch)

#### `sendMessage()`
Send interactive message to watch (requires watch to be reachable).

```typescript
import { Watch } from '@macsupport/capacitor-watch-enhanced';

try {
  const result = await Watch.sendMessage({
    message: {
      type: 'getStatus',
      detail: 'full'
    }
  });
  console.log('Watch replied:', result.reply);
} catch (error) {
  console.error('Watch not reachable:', error);
}
```

**When to use:** Interactive requests when watch is actively connected
**Requires:** Watch must be reachable (isReachable = true)
**Behavior:** Returns promise with watch's reply or error

---

#### `updateApplicationContext()`
Update application context (latest-value-only, background-capable).

```typescript
await Watch.updateApplicationContext({
  data: {
    currentPage: 'dogs',
    selectedDrugs: ['acepromazine', 'butorphanol'],
    lastUpdated: Date.now()
  }
});
```

**When to use:** Syncing current app state
**Requires:** Nothing - always works
**Behavior:** Only most recent value delivered, previous values overwritten

---

#### `transferUserInfo()`
Transfer user info to watch (background-capable queue).

```typescript
const result = await Watch.transferUserInfo({
  userInfo: {
    calculationId: '123',
    drugResults: [...],
    timestamp: Date.now()
  }
});
console.log('Transfer queued:', result.isTransferring);
```

**When to use:** Important data that must not be lost
**Requires:** Nothing - always works
**Behavior:** All transfers queued and delivered in order

---

#### `getInfo()`
Get watch connectivity status.

```typescript
const info = await Watch.getInfo();

if (info.isSupported && info.isPaired && info.isWatchAppInstalled) {
  console.log('✅ Watch app is installed');

  if (info.isReachable) {
    console.log('✅ Can send messages immediately');
  } else {
    console.log('⚠️ Watch not reachable - messages will be queued');
  }
}
```

**Returns:**
- `isSupported` - WatchConnectivity available on device
- `isPaired` - Apple Watch is paired with iPhone
- `isWatchAppInstalled` - Your watch app is installed
- `isReachable` - Watch is actively connected (can use sendMessage)
- `activationState` - 0=notActivated, 1=inactive, 2=activated

---

### Inbound Event Listeners (Watch → Phone)

#### `messageReceived`
Listen for simple messages from watch (no reply expected).

```typescript
import { Watch } from '@macsupport/capacitor-watch-enhanced';

// Set up listener
const listener = await Watch.addListener('messageReceived', async (message) => {
  console.log('📱 Received from watch:', message);

  if (message.type === 'requestPresetList') {
    await handlePresetListRequest();
  }

  if (message.type === 'loadPresetAndCalculate') {
    const { pageName, weight, unit } = message.payload;
    await handleLoadPreset(pageName, weight, unit);
  }
});

// Later, remove listener
await listener.remove();
```

**Triggered by:** Watch calling `sendMessage()` or `transferUserInfo()`
**Use case:** One-way messages from watch

---

#### `messageReceivedWithReply`
Listen for messages from watch that expect a reply.

```typescript
Watch.addListener('messageReceivedWithReply', async (message) => {
  console.log('📱 Received message with reply handler:', message);

  // Extract callback ID and process message
  const { _replyCallbackId, type, payload } = message;

  // Process request
  const result = await processWatchRequest(type, payload);

  // Send reply back to watch
  await Watch.replyToMessage({
    callbackId: _replyCallbackId,
    reply: {
      status: 'success',
      data: result
    }
  });
});
```

**Triggered by:** Watch calling `sendMessage(_:replyHandler:)`
**Use case:** Interactive request/response patterns
**Important:** Must call `replyToMessage()` to send response

---

#### `applicationContextReceived`
Listen for application context updates from watch.

```typescript
Watch.addListener('applicationContextReceived', (context) => {
  console.log('📱 Received context from watch:', context);
  // Handle watch state sync
});
```

---

#### `userInfoReceived`
Listen for user info transfers from watch.

```typescript
Watch.addListener('userInfoReceived', (userInfo) => {
  console.log('📱 Received user info from watch:', userInfo);
  // Handle queued data from watch
});
```

---

#### `reachabilityChanged`
Listen for watch reachability changes.

```typescript
Watch.addListener('reachabilityChanged', (data) => {
  if (data.isReachable) {
    console.log('✅ Watch is now reachable - can send messages');
  } else {
    console.log('⚠️ Watch not reachable - messages will be queued');
  }
});
```

**Reachable** = Watch is actively connected, can use `sendMessage()`
**Not Reachable** = Messages will be queued for later delivery

---

#### `activationStateChanged`
Listen for WatchConnectivity session activation state changes.

```typescript
Watch.addListener('activationStateChanged', (data) => {
  console.log('Session state:', data.state);
  // 0 = notActivated, 1 = inactive, 2 = activated
  if (data.error) {
    console.error('Activation error:', data.error);
  }
});
```

---

## VetDrugs Integration Example

Based on your use case, here's how to integrate with your existing `watchHomeIntegration.js`:

```typescript
// src/js/watch/watchHomeIntegration.js
import { Watch } from '@macsupport/capacitor-watch-enhanced';
import { Capacitor } from '@capacitor/core';
import { getSavedPages } from '../drugServices.js';

export async function initializeWatchHomeListeners(context) {
  if (!Capacitor.isNativePlatform()) {
    console.log('⌚ Skipping watch - not on native platform');
    return;
  }

  // Check if watch is available
  const info = await Watch.getInfo();
  if (!info.isSupported || !info.isPaired || !info.isWatchAppInstalled) {
    console.log('⌚ Watch app not available');
    return;
  }

  console.log('⌚ Initializing watch message listeners');

  // Listen for preset list requests
  Watch.addListener('messageReceived', async (message) => {
    console.log('⌚ Message from watch:', message);

    if (message.type === 'requestPresetList') {
      await handleRequestPresetList();
    }

    if (message.type === 'loadPresetAndCalculate') {
      await handleLoadPreset(message.payload, context);
    }

    if (message.type === 'updateWeightOnly') {
      await handleWeightUpdate(message.payload, context);
    }
  });

  // Listen for reachability changes
  Watch.addListener('reachabilityChanged', (data) => {
    console.log('⌚ Watch reachability:', data.isReachable);
  });

  console.log('✅ Watch listeners initialized');
}

async function handleRequestPresetList() {
  console.log('⌚ Handling preset list request');

  const savedPages = await getSavedPages();
  const watchPageList = savedPages.map(page => ({
    id: page.id,
    name: page.name,
    drugCount: page.drugs?.length || 0
  }));

  // Send to watch via application context
  await Watch.updateApplicationContext({
    data: {
      type: 'presetPageList',
      pages: watchPageList,
      totalPages: watchPageList.length,
      lastUpdated: Date.now()
    }
  });

  console.log(`✅ Sent ${watchPageList.length} pages to watch`);
}

async function handleLoadPreset(payload, context) {
  const { pageName, weight, unit } = payload;

  console.log(`⌚ Loading "${pageName}" with ${weight}${unit}`);

  // Load the page
  await context.loadSelection(pageName);
  await new Promise(resolve => setTimeout(resolve, 500));

  // Set weight
  context.setWeight(weight, unit);
  await new Promise(resolve => setTimeout(resolve, 300));

  // Get results
  const selectedItems = context.getSelectedItems();
  const calculatedDoses = selectedItems.map(item => ({
    drugName: item.name,
    dose: item.calculatedDose,
    route: item.route,
    frequency: item.frequency
  }));

  // Send results to watch
  await Watch.updateApplicationContext({
    data: {
      type: 'calculationResults',
      payload: {
        pageName,
        weight: `${weight} ${unit}`,
        drugCount: calculatedDoses.length,
        drugs: calculatedDoses,
        timestamp: Date.now()
      }
    }
  });

  console.log(`✅ Sent ${calculatedDoses.length} drug calculations to watch`);
}
```

Then in your `home.svelte`:

```typescript
import { onMount } from 'svelte';
import { initializeWatchHomeListeners } from '../js/watch/watchHomeIntegration.js';

onMount(() => {
  // Initialize watch listeners with home page context
  initializeWatchHomeListeners({
    loadSelection: (name) => loadSelection(name),
    setWeight: (weight, unit) => setWeight(weight, unit),
    getSelectedItems: () => getSelectedItems()
  });
});
```

---

## Communication Patterns

### Pattern 1: One-Way (Watch → Phone)
Watch sends data, phone processes it.

**Watch Side:**
```swift
WCSession.default.sendMessage(["type": "action"], replyHandler: nil)
```

**Phone Side:**
```typescript
Watch.addListener('messageReceived', (message) => {
  if (message.type === 'action') {
    // Handle action
  }
});
```

---

### Pattern 2: Request/Response (Watch ↔ Phone)
Watch sends request, waits for phone's reply.

**Watch Side:**
```swift
WCSession.default.sendMessage(
  ["type": "getStatus"],
  replyHandler: { reply in
    print("Phone replied: \(reply)")
  }
)
```

**Phone Side:**
```typescript
Watch.addListener('messageReceivedWithReply', async (message) => {
  const { _replyCallbackId, type } = message;

  if (type === 'getStatus') {
    const status = await getAppStatus();

    await Watch.replyToMessage({
      callbackId: _replyCallbackId,
      reply: { status: status }
    });
  }
});
```

---

### Pattern 3: Background Data Sync (Phone → Watch)
Phone sends data to watch even when watch is not actively running.

**Phone Side:**
```typescript
// Latest-value-only (overwrites previous)
await Watch.updateApplicationContext({
  data: { currentState: 'updated' }
});

// Or queued delivery (all transfers delivered)
await Watch.transferUserInfo({
  userInfo: { importantData: [...] }
});
```

**Watch Side:**
```swift
// Receives via WCSessionDelegate
func session(_ session: WCSession, didReceiveApplicationContext: [String: Any]) {
  // Handle context update
}
```

---

## Debugging

### Console Logs

The plugin adds detailed console logs with emoji prefixes:

- `📱` - Phone-side logs
- `⌚` - Watch-related operations
- `⚠️` - Warnings or errors
- `✅` - Success messages

### Check Watch Status

```typescript
const info = await Watch.getInfo();
console.log('Watch Status:', {
  supported: info.isSupported,
  paired: info.isPaired,
  installed: info.isWatchAppInstalled,
  reachable: info.isReachable,
  state: info.activationState
});
```

### Common Issues

**Issue:** Messages not received on phone
**Solution:** Check that `Watch.addListener()` is called BEFORE watch sends messages

**Issue:** "Watch not reachable" error
**Solution:** Use `updateApplicationContext()` or `transferUserInfo()` instead of `sendMessage()`

**Issue:** Reply handler timeout on watch
**Solution:** Make sure phone calls `replyToMessage()` within watch's timeout (usually 10 seconds)

---

## Migration from Custom Plugin

If you were using a custom `VetDrugsWatchPlugin`, replace:

```typescript
// OLD (custom plugin)
import { VetDrugsWatch } from './VetDrugsWatchPlugin';
VetDrugsWatch.addListener('messageReceived', handler);
```

```typescript
// NEW (enhanced plugin)
import { Watch } from '@macsupport/capacitor-watch-enhanced';
Watch.addListener('messageReceived', handler);
```

The message format and behavior are identical.

---

## Technical Details

### Architecture

1. **WatchPlugin.swift** - Main Capacitor plugin class
   - Registers with Capacitor plugin system
   - Exposes methods to JavaScript
   - Manages reply handler callbacks

2. **CapWatchDelegate.swift** - WCSessionDelegate implementation
   - Receives messages from WatchConnectivity
   - Forwards events to JavaScript via `notifyListeners()`
   - Maintains weak reference to plugin

3. **definitions.ts** - TypeScript interfaces
   - Type-safe method signatures
   - Event listener types
   - JSDoc documentation

### Thread Safety

- All WatchConnectivity delegate methods forward to JavaScript on main thread
- Reply handlers are stored in thread-safe dictionary
- Weak reference prevents retain cycles

### Memory Management

- Plugin holds weak reference to delegate
- Reply handlers automatically removed after use
- Event listeners can be removed via `listener.remove()`

---

## Contributing

Found a bug or want to add features? Open an issue or PR at:
https://github.com/macsupport/CapacitorWatchEnhanced

---

## License

MIT (same as original @capacitor/watch)

---

## Credits

Enhanced by VetCalculators
Based on @capacitor/watch by Ionic Team

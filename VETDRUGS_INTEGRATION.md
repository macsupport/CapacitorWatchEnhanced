# VetDrugs Apple Watch Integration Guide

## Quick Start

This guide shows how to integrate CapacitorWatchEnhanced into your VetDrugs app to enable Apple Watch drug calculations.

---

## Step 1: Build and Install the Plugin

```bash
# Build the enhanced plugin
cd /home/user/CapacitorWatchEnhanced/packages/capacitor-plugin
pnpm install
pnpm run build

# Install in VetDrugs
cd /home/user/VetDrugs
npm install file:///home/user/CapacitorWatchEnhanced/packages/capacitor-plugin
npx cap sync ios
```

---

## Step 2: Update Your JavaScript Integration

Replace your existing `watchHomeIntegration.js` with this working version:

```typescript
// src/js/watch/watchHomeIntegration.js
import { Watch } from '@macsupport/capacitor-watch-enhanced';
import { Capacitor } from '@capacitor/core';
import { getSavedPages } from '../drugServices.js';

/**
 * Initialize Apple Watch message listeners for VetDrugs
 * @param {Object} context - Home page context with loadSelection, setWeight, getSelectedItems
 */
export async function initializeWatchHomeListeners(context) {
  if (!Capacitor.isNativePlatform()) {
    console.log('⌚ Skipping watch - not on native platform');
    return;
  }

  console.log('⌚ Checking watch availability...');

  // Check watch status
  try {
    const info = await Watch.getInfo();
    console.log('⌚ Watch Info:', info);

    if (!info.isSupported) {
      console.log('⌚ WatchConnectivity not supported on this device');
      return;
    }

    if (!info.isPaired) {
      console.log('⌚ No Apple Watch paired');
      return;
    }

    if (!info.isWatchAppInstalled) {
      console.log('⌚ VetDrugs watch app not installed');
      return;
    }

    console.log('✅ Watch app available - initializing listeners');
  } catch (error) {
    console.error('⚠️ Failed to check watch status:', error);
    return;
  }

  // ===================================================================
  // PRIMARY LISTENER: Handle all watch messages
  // ===================================================================
  Watch.addListener('messageReceived', async (message) => {
    console.log('📱 Received message from watch:', message);

    try {
      switch (message.type) {
        case 'requestPresetList':
          await handleRequestPresetList();
          break;

        case 'loadPresetAndCalculate':
          await handleLoadPresetAndCalculate(message.payload, context);
          break;

        case 'updateWeightOnly':
          await handleWeightUpdate(message.payload, context);
          break;

        default:
          console.log('⚠️ Unknown message type:', message.type);
      }
    } catch (error) {
      console.error('❌ Error handling watch message:', error);
    }
  });

  // ===================================================================
  // REACHABILITY LISTENER: Track watch connection status
  // ===================================================================
  Watch.addListener('reachabilityChanged', (data) => {
    if (data.isReachable) {
      console.log('✅ Watch is now reachable');
    } else {
      console.log('⚠️ Watch not reachable - messages will be queued');
    }
  });

  // ===================================================================
  // USER INFO LISTENER: Handle background data transfers
  // ===================================================================
  Watch.addListener('userInfoReceived', async (userInfo) => {
    console.log('📱 Received background transfer from watch:', userInfo);
    // Handle same as messageReceived
    if (userInfo.type === 'requestPresetList') {
      await handleRequestPresetList();
    }
  });

  console.log('✅ VetDrugs watch listeners initialized successfully');
}

// ===================================================================
// MESSAGE HANDLERS
// ===================================================================

/**
 * Handle request for list of saved drug calculation pages
 */
async function handleRequestPresetList() {
  console.log('⌚ Handling preset list request from watch');

  try {
    // Fetch saved pages from Firestore
    const savedPages = await getSavedPages();

    // Format for watch display
    const watchPageList = savedPages.map(page => ({
      id: page.id,
      name: page.name,
      drugCount: page.drugs?.length || 0,
      species: page.species || 'unknown'
    }));

    console.log(`⌚ Sending ${watchPageList.length} pages to watch`);

    // Send to watch via application context (latest-value-only)
    await Watch.updateApplicationContext({
      data: {
        type: 'presetPageList',
        pages: watchPageList,
        totalPages: watchPageList.length,
        lastUpdated: Date.now()
      }
    });

    console.log('✅ Preset list sent to watch successfully');
  } catch (error) {
    console.error('❌ Failed to send preset list:', error);

    // Send error to watch
    await Watch.updateApplicationContext({
      data: {
        type: 'error',
        message: 'Failed to load drug pages',
        error: error.message
      }
    });
  }
}

/**
 * Handle request to load a preset page and calculate drug doses
 * @param {Object} payload - { pageName, weight, unit }
 * @param {Object} context - Home page context
 */
async function handleLoadPresetAndCalculate(payload, context) {
  const { pageName, weight, unit } = payload;

  console.log(`⌚ Loading preset "${pageName}" with ${weight} ${unit}`);

  try {
    // Step 1: Load the drug page
    console.log('⌚ Step 1: Loading drug page...');
    await context.loadSelection(pageName);
    await delay(500); // Allow page to load

    // Step 2: Set patient weight
    console.log(`⌚ Step 2: Setting weight to ${weight} ${unit}...`);
    context.setWeight(weight, unit);
    await delay(300); // Allow calculations to complete

    // Step 3: Get calculated results
    console.log('⌚ Step 3: Extracting calculated doses...');
    const selectedItems = context.getSelectedItems();
    const calculatedDoses = extractDrugDoses(selectedItems, weight, unit);

    console.log(`⌚ Calculated ${calculatedDoses.length} drug doses`);

    // Step 4: Send results to watch
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

    console.log('✅ Drug calculations sent to watch successfully');
  } catch (error) {
    console.error('❌ Failed to calculate drugs:', error);

    // Send error to watch
    await Watch.updateApplicationContext({
      data: {
        type: 'error',
        message: 'Failed to calculate drug doses',
        error: error.message
      }
    });
  }
}

/**
 * Handle request to update weight and recalculate
 * @param {Object} payload - { weight, unit }
 * @param {Object} context - Home page context
 */
async function handleWeightUpdate(payload, context) {
  const { weight, unit } = payload;

  console.log(`⌚ Updating weight to ${weight} ${unit}`);

  try {
    // Update weight
    context.setWeight(weight, unit);
    await delay(300); // Allow recalculation

    // Get updated results
    const selectedItems = context.getSelectedItems();
    const calculatedDoses = extractDrugDoses(selectedItems, weight, unit);

    // Send updated results to watch
    await Watch.updateApplicationContext({
      data: {
        type: 'calculationResults',
        payload: {
          weight: `${weight} ${unit}`,
          drugCount: calculatedDoses.length,
          drugs: calculatedDoses,
          timestamp: Date.now()
        }
      }
    });

    console.log('✅ Recalculated doses sent to watch');
  } catch (error) {
    console.error('❌ Failed to update weight:', error);
  }
}

// ===================================================================
// UTILITY FUNCTIONS
// ===================================================================

/**
 * Extract calculated drug doses from selected items
 * @param {Array} selectedItems - Array of selected drug items
 * @param {Number} weight - Patient weight
 * @param {String} unit - Weight unit (kg/lbs)
 * @returns {Array} Array of formatted drug doses for watch display
 */
function extractDrugDoses(selectedItems, weight, unit) {
  return selectedItems.map(item => {
    // Extract relevant calculation data
    // Adjust based on your actual data structure
    return {
      drugName: item.drugName || item.name,
      dose: item.calculatedDose || `${item.doseValue} ${item.doseUnit}`,
      volume: item.volume || null,
      route: item.route || 'IV',
      frequency: item.frequency || 'Once',
      concentration: item.concentration || null,
      notes: item.notes || null
    };
  });
}

/**
 * Delay helper for async operations
 * @param {Number} ms - Milliseconds to delay
 */
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

---

## Step 3: Initialize in home.svelte

Update your `home.svelte` to call the watch integration on mount:

```typescript
// src/pages/home.svelte
<script>
  import { onMount } from 'svelte';
  import { initializeWatchHomeListeners } from '../js/watch/watchHomeIntegration.js';

  // ... existing code ...

  onMount(() => {
    // Initialize watch communication
    initializeWatchHomeListeners({
      loadSelection: (name) => {
        // Your existing loadSelection function
        return loadSelection(name);
      },
      setWeight: (weight, unit) => {
        // Your existing setWeight function
        // Make sure it triggers recalculation
        patientWeight = weight;
        weightUnit = unit;
        // Trigger calculations...
      },
      getSelectedItems: () => {
        // Return currently selected drugs with calculated doses
        return selectedDrugs; // Your selected items array
      }
    });
  });
</script>
```

---

## Step 4: Test on Device

1. **Build and run on iPhone:**
   ```bash
   cd /home/user/VetDrugs
   npm run build-cap
   npx cap sync ios
   npx cap open ios
   ```

2. **In Xcode:**
   - Select your iPhone as target device
   - Build and run (Cmd+R)

3. **Check console logs:**
   Look for these logs confirming initialization:
   ```
   ⌚ Checking watch availability...
   ⌚ Watch Info: { isSupported: true, isPaired: true, ... }
   ✅ Watch app available - initializing listeners
   ✅ VetDrugs watch listeners initialized successfully
   ```

4. **Test from watch:**
   - Open VetDrugs watch app
   - Request preset list
   - Check iPhone console for:
     ```
     📱 Received message from watch: { type: 'requestPresetList' }
     ⌚ Handling preset list request from watch
     ✅ Preset list sent to watch successfully
     ```

---

## Step 5: Verify Communication

### Test Sequence:

1. **Watch sends:** `{ type: 'requestPresetList' }`
2. **iPhone logs:** `📱 Received message from watch...`
3. **iPhone sends back:** Preset list via `updateApplicationContext()`
4. **Watch receives:** List of drug pages

Then:

1. **Watch sends:** `{ type: 'loadPresetAndCalculate', payload: { pageName: 'Dogs - Emergency', weight: 5.2, unit: 'kg' } }`
2. **iPhone logs:** `⌚ Loading preset "Dogs - Emergency" with 5.2 kg`
3. **iPhone calculates doses**
4. **iPhone sends back:** Drug calculation results
5. **Watch displays:** Calculated doses

---

## Debugging

### Enable Verbose Logging

Check Xcode console for these log patterns:

**Plugin Loading:**
```
📱 WatchPlugin loading...
📱 WatchPlugin loaded successfully
```

**Message Reception:**
```
📱 PHONE WatchDelegate didReceiveMessage: [type: requestPresetList]
📱 Received message from watch: { type: 'requestPresetList' }
```

**Application Context Sent:**
```
📱 WatchPlugin updateApplicationContext: [type: presetPageList, pages: [...]]
```

### Common Issues

**Issue:** "Watch app not available" despite watch being paired

**Solution:** Check that your watch app bundle ID is `[your.app.id].watchapp`

---

**Issue:** Messages received on iPhone but JavaScript handler not called

**Solution:** Make sure `Watch.addListener()` is called BEFORE watch sends messages (use `onMount`)

---

**Issue:** "Watch not reachable" errors

**Solution:** Your watch is using `transferUserInfo()` instead of `sendMessage()`, which is fine - messages will be delivered via `userInfoReceived` listener

---

## Message Format Reference

### Watch → iPhone

```typescript
// Request preset list
{
  type: 'requestPresetList'
}

// Load and calculate
{
  type: 'loadPresetAndCalculate',
  payload: {
    pageName: 'Dogs - Emergency',
    weight: 5.2,
    unit: 'kg'
  }
}

// Update weight only
{
  type: 'updateWeightOnly',
  payload: {
    weight: 6.0,
    unit: 'kg'
  }
}
```

### iPhone → Watch

```typescript
// Preset list response
{
  type: 'presetPageList',
  pages: [
    {
      id: '123',
      name: 'Dogs - Emergency',
      drugCount: 5,
      species: 'dog'
    }
  ],
  totalPages: 10,
  lastUpdated: 1234567890
}

// Calculation results
{
  type: 'calculationResults',
  payload: {
    pageName: 'Dogs - Emergency',
    weight: '5.2 kg',
    drugCount: 5,
    drugs: [
      {
        drugName: 'Acepromazine',
        dose: '2.6 mg',
        volume: '0.26 ml',
        route: 'IV',
        frequency: 'Once',
        concentration: '10 mg/ml'
      }
    ],
    timestamp: 1234567890
  }
}

// Error response
{
  type: 'error',
  message: 'Failed to load drug pages',
  error: 'Network timeout'
}
```

---

## Performance Tips

1. **Use `updateApplicationContext()` for results** - Latest-value-only, won't queue up multiple results
2. **Use `transferUserInfo()` for important data** - Queued delivery, won't be lost
3. **Add delays between operations** - Allow time for page loads and calculations
4. **Batch drug data** - Send all calculated doses in single message

---

## Next Steps

Once working:
1. Add error handling for network timeouts
2. Add loading indicators on watch
3. Implement dose history/favorites
4. Add voice input for weight on watch

---

## Support

Issues? Open a ticket at:
https://github.com/macsupport/CapacitorWatchEnhanced/issues

Include:
- Xcode console logs
- Watch app version
- iOS version
- Steps to reproduce

/// <reference types="@capacitor/cli" />
import type { PluginListenerHandle } from '@capacitor/core';

export interface WatchPlugin {
  // ===================================================================
  // OUTBOUND METHODS (Phone → Watch)
  // ===================================================================

  /**
   * Replaces the current watch UI with watchUI
   * @deprecated Use sendMessage or updateApplicationContext for new implementations
   */
  updateWatchUI(options: { watchUI: string }): Promise<void>;

  /**
   * Updates the watch's state data (variables in Text() elements)
   * @deprecated Use sendMessage or updateApplicationContext for new implementations
   */
  updateWatchData(options: { data: { [key: string]: string } }): Promise<void>;

  /**
   * Send interactive message to watch (requires watch to be reachable)
   * This method waits for a reply from the watch.
   * Use this for request/response patterns when the watch is actively reachable.
   *
   * @param options - Object containing the message to send
   * @returns Promise resolving to the watch's reply (if any)
   * @throws Error if watch is not reachable or message fails to send
   * @example
   * ```typescript
   * const result = await Watch.sendMessage({
   *   message: { type: 'getStatus', payload: { detail: 'full' } }
   * });
   * console.log('Watch replied:', result.reply);
   * ```
   */
  sendMessage(options: { message: any }): Promise<{ reply?: any }>;

  /**
   * Update application context (latest-value-only, background-capable)
   * The watch receives only the most recent context. Previous values are overwritten.
   * This is ideal for syncing the current app state.
   *
   * @param options - Object containing data to send as application context
   * @returns Promise resolving when context is queued for delivery
   * @example
   * ```typescript
   * await Watch.updateApplicationContext({
   *   data: {
   *     currentPage: 'dogs',
   *     selectedDrugs: ['acepromazine', 'butorphanol'],
   *     lastUpdated: Date.now()
   *   }
   * });
   * ```
   */
  updateApplicationContext(options: { data: any }): Promise<{ success: boolean }>;

  /**
   * Transfer user info to watch (background-capable queue)
   * All transfers are queued and delivered in order. Use this for important
   * data that must not be lost (e.g., calculation results, saved presets).
   *
   * @param options - Object containing userInfo to transfer
   * @returns Promise resolving with transfer status
   * @example
   * ```typescript
   * const result = await Watch.transferUserInfo({
   *   userInfo: {
   *     calculationId: '123',
   *     drugResults: [...],
   *     timestamp: Date.now()
   *   }
   * });
   * console.log('Transfer queued:', result.isTransferring);
   * ```
   */
  transferUserInfo(options: { userInfo: any }): Promise<{ success: boolean; isTransferring: boolean }>;

  /**
   * Reply to a message received with reply handler
   * Use this to respond to messages received via the 'messageReceivedWithReply' event.
   *
   * @param options - Object containing callbackId and reply data
   * @returns Promise resolving when reply is sent
   * @example
   * ```typescript
   * Watch.addListener('messageReceivedWithReply', async (message) => {
   *   const result = await processRequest(message);
   *   await Watch.replyToMessage({
   *     callbackId: message._replyCallbackId,
   *     reply: { status: 'success', result }
   *   });
   * });
   * ```
   */
  replyToMessage(options: { callbackId: string; reply: any }): Promise<void>;

  /**
   * Get watch connectivity status and information
   * @returns Promise resolving to watch connection information
   * @example
   * ```typescript
   * const info = await Watch.getInfo();
   * if (info.isSupported && info.isPaired && info.isWatchAppInstalled) {
   *   console.log('Watch is ready!');
   *   if (info.isReachable) {
   *     console.log('Can send messages immediately');
   *   }
   * }
   * ```
   */
  getInfo(): Promise<{
    isSupported: boolean;
    isReachable: boolean;
    isPaired: boolean;
    isWatchAppInstalled: boolean;
    activationState?: number;
  }>;

  // ===================================================================
  // EVENT LISTENERS (Watch → Phone)
  // ===================================================================

  /**
   * Listen for simple messages from watch (no reply expected)
   * This is called when the watch sends a message using sendMessage() or transferUserInfo()
   *
   * @param eventName - Must be 'messageReceived'
   * @param listenerFunc - Callback function receiving the message data
   * @returns Promise resolving to listener handle for removal
   * @example
   * ```typescript
   * const listener = await Watch.addListener('messageReceived', (message) => {
   *   console.log('Received from watch:', message);
   *   if (message.type === 'requestPresetList') {
   *     handlePresetListRequest();
   *   }
   * });
   *
   * // Later, remove listener
   * await listener.remove();
   * ```
   */
  addListener(
    eventName: 'messageReceived',
    listenerFunc: (message: any) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for messages from watch that expect a reply
   * Use replyToMessage() with the _replyCallbackId to send response
   *
   * @param eventName - Must be 'messageReceivedWithReply'
   * @param listenerFunc - Callback function receiving message with _replyCallbackId
   * @returns Promise resolving to listener handle for removal
   * @example
   * ```typescript
   * Watch.addListener('messageReceivedWithReply', async (message) => {
   *   const { _replyCallbackId, ...actualMessage } = message;
   *   const result = await handleRequest(actualMessage);
   *
   *   await Watch.replyToMessage({
   *     callbackId: _replyCallbackId,
   *     reply: { status: 'success', data: result }
   *   });
   * });
   * ```
   */
  addListener(
    eventName: 'messageReceivedWithReply',
    listenerFunc: (message: any & { _replyCallbackId: string }) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for application context updates from watch
   * This is called when watch updates its application context (latest-value-only)
   *
   * @param eventName - Must be 'applicationContextReceived'
   * @param listenerFunc - Callback function receiving the context data
   * @returns Promise resolving to listener handle for removal
   */
  addListener(
    eventName: 'applicationContextReceived',
    listenerFunc: (context: any) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for user info transfers from watch
   * This is called for each queued userInfo transfer from the watch
   *
   * @param eventName - Must be 'userInfoReceived'
   * @param listenerFunc - Callback function receiving the user info data
   * @returns Promise resolving to listener handle for removal
   */
  addListener(
    eventName: 'userInfoReceived',
    listenerFunc: (userInfo: any) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for watch reachability changes
   * Reachable = watch is actively connected and can receive messages immediately
   * Not reachable = messages will be queued for later delivery
   *
   * @param eventName - Must be 'reachabilityChanged'
   * @param listenerFunc - Callback function receiving reachability status
   * @returns Promise resolving to listener handle for removal
   * @example
   * ```typescript
   * Watch.addListener('reachabilityChanged', (data) => {
   *   if (data.isReachable) {
   *     console.log('Watch is now reachable - can send messages');
   *   } else {
   *     console.log('Watch not reachable - messages will be queued');
   *   }
   * });
   * ```
   */
  addListener(
    eventName: 'reachabilityChanged',
    listenerFunc: (data: { isReachable: boolean }) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for WatchConnectivity session activation state changes
   * State values: 0 = notActivated, 1 = inactive, 2 = activated
   *
   * @param eventName - Must be 'activationStateChanged'
   * @param listenerFunc - Callback function receiving activation state
   * @returns Promise resolving to listener handle for removal
   */
  addListener(
    eventName: 'activationStateChanged',
    listenerFunc: (data: { state: number; error?: string }) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for session inactive events (iOS only)
   *
   * @param eventName - Must be 'sessionBecameInactive'
   * @param listenerFunc - Callback function
   * @returns Promise resolving to listener handle for removal
   */
  addListener(
    eventName: 'sessionBecameInactive',
    listenerFunc: (data: {}) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for session deactivated events (iOS only)
   * The session is automatically reactivated after this event
   *
   * @param eventName - Must be 'sessionDeactivated'
   * @param listenerFunc - Callback function
   * @returns Promise resolving to listener handle for removal
   */
  addListener(
    eventName: 'sessionDeactivated',
    listenerFunc: (data: {}) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Legacy listener for watch commands (backward compatibility)
   * @deprecated Use 'messageReceived' event listener instead
   *
   * @param eventName - Must be 'runCommand'
   * @param listenerFunc - Callback function receiving command string
   * @returns Promise resolving to listener handle for removal
   */
  addListener(
    eventName: 'runCommand',
    listenerFunc: (data: { command: string }) => void
  ): Promise<PluginListenerHandle>;
}

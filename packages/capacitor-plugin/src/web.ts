import { WebPlugin } from '@capacitor/core';

import type { WatchPlugin } from './definitions';

export class WatchWeb extends WebPlugin implements WatchPlugin {
  // Legacy methods (backward compatibility)
  async setWatchUI(_options: { watchUI: string }): Promise<void> {
    return Promise.reject('Watch plugin not available on web');
  }

  async updateWatchUI(_options: { watchUI: string }): Promise<void> {
    return Promise.reject('Watch plugin not available on web');
  }

  async updateWatchData(_options: { data: { [key: string]: string } }): Promise<void> {
    return Promise.reject('Watch plugin not available on web');
  }

  // New enhanced methods
  async sendMessage(_options: { message: any }): Promise<{ reply?: any }> {
    return Promise.reject('Watch plugin not available on web');
  }

  async updateApplicationContext(_options: { data: any }): Promise<{ success: boolean }> {
    return Promise.reject('Watch plugin not available on web');
  }

  async transferUserInfo(_options: { userInfo: any }): Promise<{ success: boolean; isTransferring: boolean }> {
    return Promise.reject('Watch plugin not available on web');
  }

  async replyToMessage(_options: { callbackId: string; reply: any }): Promise<void> {
    return Promise.reject('Watch plugin not available on web');
  }

  async getInfo(): Promise<{
    isSupported: boolean;
    isReachable: boolean;
    isPaired: boolean;
    isWatchAppInstalled: boolean;
    activationState?: number;
  }> {
    // Return false values for web platform
    return {
      isSupported: false,
      isReachable: false,
      isPaired: false,
      isWatchAppInstalled: false,
      activationState: 0,
    };
  }
}

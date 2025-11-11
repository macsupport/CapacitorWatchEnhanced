#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(WatchPlugin, "Watch",
   // Legacy methods (backward compatibility)
   CAP_PLUGIN_METHOD(setWatchUI, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(updateWatchUI, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(updateWatchData, CAPPluginReturnPromise);

   // New enhanced methods for bidirectional communication
   CAP_PLUGIN_METHOD(sendMessage, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(updateApplicationContext, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(transferUserInfo, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(replyToMessage, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(getInfo, CAPPluginReturnPromise);
);

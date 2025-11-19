import Foundation
import Capacitor
import WatchConnectivity

@objc(WatchPlugin)
public class WatchPlugin: CAPPlugin {

    // Store pending reply handlers for async message responses
    internal var pendingReplies: [String: ([String: Any]) -> Void] = [:]

    override public func load() {
        print("📱 WatchPlugin loading...")

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleApplicationActive(notification:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleUrlOpened(notification:)),
                                               name: Notification.Name.capacitorOpenURL,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleUniversalLink(notification:)),
                                               name: Notification.Name.capacitorOpenUniversalLink,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleCommandFromWatch(_:)),
                                               name: Notification.Name(COMMAND_KEY),
                                               object: nil)

        // Link delegate to this plugin instance for bidirectional communication
        print("📱 DIAGNOSTIC: Linking WatchPlugin to CapWatchSessionDelegate...")
        CapWatchSessionDelegate.shared.plugin = self
        print("📱 DIAGNOSTIC: Delegate.plugin linked successfully. Is nil? \(CapWatchSessionDelegate.shared.plugin == nil)")

        print("📱 WatchPlugin loaded successfully")
    }
    
    @objc func handleApplicationActive(notification: NSNotification) {
        assert(WCSession.isSupported(), "This sample requires Watch Connectivity support!")
        WCSession.default.delegate = CapWatchSessionDelegate.shared
        WCSession.default.activate()
    }
    
    @objc func handleUrlOpened(notification: NSNotification) {
        
    }

    @objc func handleUniversalLink(notification: NSNotification) {
        
    }
    
    @objc func handleCommandFromWatch(_ notification: NSNotification) {
        if let command = notification.userInfo![COMMAND_KEY] as? String {
            print("WATCH process: \(command)")
            notifyListeners("runCommand", data: ["command": command])
        }
    }
    
    @objc func updateWatchUI(_ call: CAPPluginCall) {
        guard let newUI = call.getString("watchUI")  else {
            return
        }
        
        CapWatchSessionDelegate.shared.WATCH_UI = newUI
        CapWatchSessionDelegate.shared.sendUI()
        
        call.resolve()
    }
    
    @objc func updateWatchData(_ call: CAPPluginCall) {
        guard let newData = call.getObject("data") as? [String: String] else {
            return
        }

        CapWatchSessionDelegate.shared.updateViewData(newData)
        call.resolve()
    }

    // MARK: - New Enhanced Methods for Bidirectional Communication

    @objc func sendMessage(_ call: CAPPluginCall) {
        guard let message = call.getObject("message") else {
            call.reject("Missing message parameter")
            return
        }

        guard WCSession.default.isReachable else {
            call.reject("Watch not reachable")
            return
        }

        print("📱 WatchPlugin sendMessage: \(message)")

        WCSession.default.sendMessage(message, replyHandler: { reply in
            print("📱 WatchPlugin received reply: \(reply)")
            call.resolve(["reply": reply])
        }, errorHandler: { error in
            print("⚠️ WatchPlugin sendMessage error: \(error.localizedDescription)")
            call.reject("Failed to send message: \(error.localizedDescription)")
        })
    }

    @objc func updateApplicationContext(_ call: CAPPluginCall) {
        guard let data = call.getObject("data") else {
            call.reject("Missing data parameter")
            return
        }

        print("📱 WatchPlugin updateApplicationContext: \(data)")

        do {
            try WCSession.default.updateApplicationContext(data)
            call.resolve(["success": true])
        } catch {
            print("⚠️ WatchPlugin updateApplicationContext error: \(error.localizedDescription)")
            call.reject("Failed to update context: \(error.localizedDescription)")
        }
    }

    @objc func transferUserInfo(_ call: CAPPluginCall) {
        guard let userInfo = call.getObject("userInfo") else {
            call.reject("Missing userInfo parameter")
            return
        }

        print("📱 WatchPlugin transferUserInfo: \(userInfo)")

        let transfer = WCSession.default.transferUserInfo(userInfo)
        call.resolve([
            "success": true,
            "isTransferring": transfer.isTransferring
        ])
    }

    @objc func replyToMessage(_ call: CAPPluginCall) {
        guard let callbackId = call.getString("callbackId"),
              let reply = call.getObject("reply"),
              let replyHandler = pendingReplies[callbackId] else {
            call.reject("Invalid callback ID or no pending reply handler")
            return
        }

        print("📱 WatchPlugin replying to message with callbackId: \(callbackId)")

        replyHandler(reply)
        pendingReplies.removeValue(forKey: callbackId)
        call.resolve()
    }

    @objc func getInfo(_ call: CAPPluginCall) {
        guard WCSession.isSupported() else {
            call.resolve([
                "isSupported": false,
                "isReachable": false,
                "isPaired": false,
                "isWatchAppInstalled": false
            ])
            return
        }

        let session = WCSession.default
        call.resolve([
            "isSupported": true,
            "isReachable": session.isReachable,
            "isPaired": session.isPaired,
            "isWatchAppInstalled": session.isWatchAppInstalled,
            "activationState": session.activationState.rawValue
        ])
    }

}

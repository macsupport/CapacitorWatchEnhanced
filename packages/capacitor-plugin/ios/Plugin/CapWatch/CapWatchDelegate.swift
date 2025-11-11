//
//  WatchSessionDelegate.swift
//
//
//  Created by Dan Giralté on 2/24/23.
//

import WatchConnectivity
import CapacitorBackgroundRunner

public class CapWatchSessionDelegate : NSObject, WCSessionDelegate {
    var WATCH_UI = ""

    public static var shared = CapWatchSessionDelegate()

    // Weak reference to plugin for notifying JavaScript listeners
    weak var plugin: WatchPlugin?
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("PHONE WatchDelegate activationDidCompleteWith - state: \(activationState.rawValue)")

        // Forward activation state to JavaScript
        var data: [String: Any] = ["state": activationState.rawValue]
        if let error = error {
            data["error"] = error.localizedDescription
            print("PHONE WatchDelegate activation error: \(error.localizedDescription)")
        }
        plugin?.notifyListeners("activationStateChanged", data: data)
    }
    
    #if os(iOS)

    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("PHONE WatchDelegate sessionDidBecomeInactive")
        plugin?.notifyListeners("sessionBecameInactive", data: [:])
    }

    public func sessionDidDeactivate(_ session: WCSession) {
        print("PHONE WatchDelegate sessionDidDeactivate - reactivating")
        plugin?.notifyListeners("sessionDeactivated", data: [:])
        // Automatically reactivate the session
        session.activate()
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        print("PHONE WatchDelegate reachabilityDidChange - isReachable: \(session.isReachable)")
        plugin?.notifyListeners("reachabilityChanged", data: ["isReachable": session.isReachable])
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 PHONE WatchDelegate didReceiveMessage: \(message)")

        // Keep existing BackgroundRunner integration
        var args: [String: Any] = [:]
        args["message"] = message

        do {
            try BackgroundRunner.shared.dispatchEvent(event: "WatchConnectivity_didReceiveMessage", inputArgs: args)
        } catch {
            print("⚠️ BackgroundRunner dispatch error: \(error)")
        }

        // NEW: Forward to JavaScript listeners (generic message)
        plugin?.notifyListeners("messageReceived", data: message)

        // Keep legacy handleWatchMessage for backward compatibility
        handleWatchMessage(message)
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 PHONE WatchDelegate didReceiveMessage with replyHandler: \(message)")

        // Generate callback ID for async reply support
        let callbackId = UUID().uuidString
        var messageWithCallback = message
        messageWithCallback["_replyCallbackId"] = callbackId

        // Store reply handler for later use
        plugin?.pendingReplies[callbackId] = replyHandler

        // Forward to JavaScript with callback ID
        plugin?.notifyListeners("messageReceivedWithReply", data: messageWithCallback)

        // Also handle with legacy logic
        handleWatchMessage(message)
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("📱 PHONE WatchDelegate didReceiveApplicationContext: \(applicationContext)")

        // NEW: Forward to JavaScript listeners
        plugin?.notifyListeners("applicationContextReceived", data: applicationContext)

        // Keep legacy behavior
        handleWatchMessage(applicationContext)
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("📱 PHONE WatchDelegate didReceiveUserInfo: \(userInfo)")

        // Keep existing BackgroundRunner integration
        var args: [String: Any] = [:]
        args["userInfo"] = userInfo

        do {
            try BackgroundRunner.shared.dispatchEvent(event: "WatchConnectivity_didReceiveUserInfo", inputArgs: args)
        } catch {
            print("⚠️ BackgroundRunner dispatch error: \(error)")
        }

        // NEW: Forward to JavaScript listeners
        plugin?.notifyListeners("userInfoReceived", data: userInfo)

        // Keep legacy behavior
        handleWatchMessage(userInfo)
    }
        
    func updateViewData(_ data: [String: String]) {
        DispatchQueue.main.async {
            let _ = WCSession.default.transferUserInfo([DATA_KEY: data])
        }
    }
    
    func sendUI() {
        let _ = WCSession.default.transferUserInfo([UI_KEY : WATCH_UI])
    }
    
    func commandToJS(_ command: String) {
        NotificationCenter.default.post(name: Notification.Name(COMMAND_KEY),
                                        object: nil,
                                        userInfo: [COMMAND_KEY: command])
    }
    
    func handleWatchMessage(_ userInfo: [String: Any]) {
        if let command = userInfo[REQUESTUI_KEY] as? String {
            if command == REQUESTUI_VALUE {
                sendUI()
            }
        }
        
        if let command = userInfo[COMMAND_KEY] as? String {
            print("PHONE process: \(command)")
            commandToJS(command)
        }
    }

    #endif
}

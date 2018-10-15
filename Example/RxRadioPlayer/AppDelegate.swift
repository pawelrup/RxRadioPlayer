//
//  AppDelegate.swift
//  HRnew
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		let sceneCoordinator = SceneCoordinator(window: window!)
		let playerViewModel = PlayerViewModel(sceneCoordinator: sceneCoordinator)
		let playerScene = Scene.player(playerViewModel)
		sceneCoordinator.transition(to: playerScene, type: .root)

		// Let application receiving remote control events
		application.beginReceivingRemoteControlEvents()
		// Setting application as first responder
		application.becomeFirstResponder()

		return true
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		application.beginBackgroundTask(expirationHandler: nil)
		application.beginReceivingRemoteControlEvents()
	}

	func applicationWillTerminate(_ application: UIApplication) {
		application.endReceivingRemoteControlEvents()
		application.resignFirstResponder()
	}
}

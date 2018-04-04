//
//  SceneCoordinator.swift
//  HRnew
//
//  Created by Pawel Rup on 28.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SceneCoordinator: SceneCoordinatorType {
	
	private var window: UIWindow
	private var currentViewController: UIViewController
	
	required init(window: UIWindow) {
		self.window = window
		currentViewController = window.rootViewController!
	}
	
	static func actualViewController(for viewController: UIViewController) -> UIViewController {
		if let navigationController = viewController as? UINavigationController {
			return navigationController.viewControllers.first!
		}
		return viewController
	}
	
	@discardableResult
	func transition(to scene: Scene, type: SceneTransitionType) -> Completable {
		let subject = PublishSubject<Void>()
		let viewController = scene.viewController
		switch type {
		case .root:
			currentViewController = SceneCoordinator.actualViewController(for: viewController)
			window.rootViewController = viewController
			subject.onCompleted()
			
		case .push:
			guard let navigationController = currentViewController.navigationController else {
				fatalError("Can't push a view controller without a current navigation controller")
			}
			// one-off subscription to be notified when push complete
			_ = navigationController.rx.delegate
				.sentMessage(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
				.map { _ in }
				.bind(to: subject)
			navigationController.pushViewController(viewController, animated: true)
			currentViewController = SceneCoordinator.actualViewController(for: viewController)
			
		case .modal:
			currentViewController.present(viewController, animated: true) {
				subject.onCompleted()
			}
		}
		return subject.asObservable()
			.take(1)
			.ignoreElements()
	}
	
	func pop(animated: Bool) -> Completable {
		let subject = PublishSubject<Void>()
		if let presenter = currentViewController.presentingViewController {
			// Dismiss a modal controller
			currentViewController.dismiss(animated: animated) {
				self.currentViewController = SceneCoordinator.actualViewController(for: presenter)
				subject.onCompleted()
			}
		} else if let navigationController = currentViewController.navigationController {
			// navigate up the stack
			// one-off subscription to be notified when pop complete
			_ = navigationController.rx.delegate
				.sentMessage(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
				.map { _ in }
				.bind(to: subject)
			guard navigationController.popViewController(animated: animated) != nil else {
				fatalError("Can't navigate back from \(currentViewController)")
			}
			currentViewController = SceneCoordinator.actualViewController(for: navigationController.viewControllers.last!)
		} else {
			fatalError("Not a modal, no navigation controller: can't navigate back from \(currentViewController)")
		}
		return subject.asObservable()
			.take(1)
			.ignoreElements()
	}
}

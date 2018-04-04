//
//  SceneCoordinatorType.swift
//  HRnew
//
//  Created by Pawel Rup on 28.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import RxSwift
protocol SceneCoordinatorType {
	
	/// Transition to another scene
	@discardableResult
	func transition(to scene: Scene, type: SceneTransitionType) -> Completable
	
	/// Pop scene from navigation stack or dismiss current modal
	@discardableResult
	func pop(animated: Bool) -> Completable
}

extension SceneCoordinatorType {
	@discardableResult
	func pop() -> Completable {
		return pop(animated: true)
	}
}

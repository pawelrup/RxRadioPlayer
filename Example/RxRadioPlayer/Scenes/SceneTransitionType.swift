//
//  SceneTransitionType.swift
//  HRnew
//
//  Created by Pawel Rup on 28.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation

enum SceneTransitionType {
	// you can extend this to add animated transition types,
	// interactive transitions and even child view controllers!
	
	case root       // Make view controller the root view controller
	case push       // Push view controller to navigation stack
	case modal      // Present view controller modally
}

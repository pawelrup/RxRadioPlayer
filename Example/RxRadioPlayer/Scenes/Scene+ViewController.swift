//
//  Scene+ViewController.swift
//  HRnew
//
//  Created by Pawel Rup on 28.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import UIKit

extension Scene {
	var viewController: UIViewController {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		switch self {
		case .player(let viewModel):
			let navigationController = storyboard.instantiateViewController(withIdentifier: "PlyerNavigationController") as! UINavigationController
			var viewController = navigationController.viewControllers.first as! PlayerViewController
			viewController.bindViewModel(to: viewModel)
			return navigationController
		}
	}
}

//
//  BindableType.swift
//  HRnew
//
//  Created by Pawel Rup on 28.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import UIKit

protocol BindableType {
	associatedtype ViewModelType
	
	var viewModel: ViewModelType! { get set }
	
	func bindViewModel()
}

extension BindableType where Self: UIViewController {
	
	mutating func bindViewModel(to model: Self.ViewModelType) {
		viewModel = model
		if #available(iOS 9.0, *) {
			loadViewIfNeeded()
		} else {
			_ = self.view
		}
		bindViewModel()
	}
}

//
//  Cover.swift
//  HRnew
//
//  Created by Pawel Rup on 28.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import UIKit

struct Cover {
	static let `default` = Cover(image: UIImage(named: "trollface")!, infoCenterImage: UIImage(named: "trollface")!)
	
	let image: UIImage
	let infoCenterImage: UIImage
	
	init(image: UIImage) {
		self.image = image
		self.infoCenterImage = image
	}
	
	init(image: UIImage, infoCenterImage: UIImage) {
		self.image = image
		self.infoCenterImage = infoCenterImage
	}
}

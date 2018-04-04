//
//  CoverLoader.swift
//  HRnew
//
//  Created by Pawel Rup on 28.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import UIKit
import RxSwift

class CoverLoader {
	
	func loadCover(for url: URL) -> Observable<UIImage?> {
		let request = URLRequest(url: url)
		return URLSession.shared.rx.data(request: request)
			.map { (data: Data) in
				return UIImage(data: data)
			}
			.catchErrorJustReturn(nil)
	}
}

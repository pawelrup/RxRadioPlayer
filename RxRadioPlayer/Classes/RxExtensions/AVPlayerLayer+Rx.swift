//
//  AVPlayerLayer+Rx.swift
//  HRnew
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

extension Reactive where Base: AVPlayerLayer {
	public var readyForDisplay: Observable<Bool> {
		return self.observe(Bool.self, #keyPath(AVPlayerLayer.readyForDisplay))
			.map { $0 ?? false }
	}
}

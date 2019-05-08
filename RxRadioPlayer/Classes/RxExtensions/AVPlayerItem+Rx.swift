//
//  AVPlayerItem+Rx.swift
//  HRnew
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

extension Reactive where Base: AVPlayerItem {
	public var status: Observable<AVPlayerItem.Status> {
		return observe(AVPlayerItem.Status.self, #keyPath(AVPlayerItem.status))
			.map { $0 ?? .unknown }
	}

	public var error: Observable<NSError?> {
		return observe(NSError.self, #keyPath(AVPlayerItem.error))
	}

	public var duration: Observable<CMTime> {
		return observe(CMTime.self, #keyPath(AVPlayerItem.duration))
			.map { $0 ?? .zero }
	}

	public var playbackLikelyToKeepUp: Observable<Bool> {
		return observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
			.map { $0 ?? false }
	}

	public var playbackBufferFull: Observable<Bool> {
		return observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackBufferFull))
			.map { $0 ?? false }
	}

	public var playbackBufferEmpty: Observable<Bool> {
		return observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
			.map { $0 ?? false }
	}

	public var didPlayToEnd: Observable<Notification> {
		let notificationCenter = NotificationCenter.default
		return notificationCenter.rx.notification(.AVPlayerItemDidPlayToEndTime, object: base)
	}

	public var loadedTimeRanges: Observable<[CMTimeRange]> {
		return observe([NSValue].self, #keyPath(AVPlayerItem.loadedTimeRanges))
			.map { $0 ?? [] }
			.map { values in values.map { $0.timeRangeValue } }
	}

	public var timedMetadata: Observable<[AVMetadataItem]> {
		return observe([AVMetadataItem].self, #keyPath(AVPlayerItem.timedMetadata))
			.map { $0 ?? [] }
	}
}

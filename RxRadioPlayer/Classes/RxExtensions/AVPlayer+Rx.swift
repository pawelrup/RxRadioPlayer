//
//  AVPlayer+Rx.swift
//  HRnew
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

extension Reactive where Base: AVPlayer {
	public var rate: Observable<Float> {
		return observe(Float.self, #keyPath(AVPlayer.rate))
			.map { $0 ?? 0 }
	}

	public var currentItem: Observable<AVPlayerItem?> {
		return observe(AVPlayerItem.self, #keyPath(AVPlayer.currentItem))
	}

	public var status: Observable<AVPlayer.Status> {
		return observe(AVPlayer.Status.self, #keyPath(AVPlayer.status))
			.map { $0 ?? .unknown }
	}

	public var error: Observable<NSError?> {
		return observe(NSError.self, #keyPath(AVPlayer.error))
	}

	@available(iOS 10.0, tvOS 10.0, *)
	public var reasonForWaitingToPlay: Observable<AVPlayer.WaitingReason?> {
		return observe(AVPlayer.WaitingReason.self, #keyPath(AVPlayer.reasonForWaitingToPlay))
	}

	@available(iOS 10.0, tvOS 10.0, *)
	public var timeControlStatus: Observable<AVPlayer.TimeControlStatus> {
		return observe(AVPlayer.TimeControlStatus.self, #keyPath(AVPlayer.timeControlStatus))
			.map { $0 ?? .waitingToPlayAtSpecifiedRate }
	}

	public func periodicTimeObserver(interval: CMTime) -> Observable<CMTime> {
		return Observable.create { observer in
			let timeObserver = self.base.addPeriodicTimeObserver(forInterval: interval, queue: nil) { time in
				observer.onNext(time)
			}

			return Disposables.create { self.base.removeTimeObserver(timeObserver) }
		}
	}

	public func boundaryTimeObserver(times: [CMTime]) -> Observable<Void> {
		return Observable.create { observer in
			let timeValues = times.map { NSValue(time: $0) }
			let timeObserver = self.base.addBoundaryTimeObserver(forTimes: timeValues, queue: nil) {
				observer.onNext(())
			}

			return Disposables.create { self.base.removeTimeObserver(timeObserver) }
		}
	}
}

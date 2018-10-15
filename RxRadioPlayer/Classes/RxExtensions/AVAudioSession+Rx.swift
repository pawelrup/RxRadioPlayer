//
//  AVAudioSession+Rx.swift
//  HRnew
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa
import RxSwiftExt

@available(iOS 6.0, tvOS 9.0, *)
public typealias AVAudioSessionRouteChangeInfo = (reason: AVAudioSession.RouteChangeReason, previousRouteDescription: AVAudioSessionRouteDescription?)

@available(iOS 6.0, tvOS 9.0, *)
extension Reactive where Base: AVAudioSession {

	public var routeChange: Observable<AVAudioSessionRouteChangeInfo> {
		return NotificationCenter.default.rx.notification(AVAudioSession.routeChangeNotification, object: base)
			.map { $0.userInfo }
			.map {
				let reasonRaw = $0?[AVAudioSessionRouteChangeReasonKey] as? UInt
				let previousRoute = $0?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
				return (reasonRaw, previousRoute)
			}
			.map { (reasonRaw: UInt?, previousRoute: AVAudioSessionRouteDescription?) -> AVAudioSessionRouteChangeInfo in
				let reason: AVAudioSession.RouteChangeReason
				if let raw = reasonRaw {
					reason = AVAudioSession.RouteChangeReason(rawValue: raw) ?? .unknown
				} else {
					reason = .unknown
				}
				return (reason: reason, previousRouteDescription: previousRoute)
		}
	}
}

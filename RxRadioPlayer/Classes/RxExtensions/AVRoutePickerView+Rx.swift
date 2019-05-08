//
//  AVRoutePickerView+Rx.swift
//  RxRadioPlayer
//
//  Created by Pawel Rup on 08/05/2019.
//

import Foundation
import AVKit
import RxSwift
import RxCocoa

@available(iOS 11.0, tvOS 11.0, *)
extension AVRoutePickerView: HasDelegate {
	public typealias Delegate = AVRoutePickerViewDelegate
}

@available(iOS 11.0, tvOS 11.0, *)
private class RxAVRoutePickerViewDelegateProxy: DelegateProxy<AVRoutePickerView, AVRoutePickerViewDelegate>, DelegateProxyType, AVRoutePickerViewDelegate {

	public weak private (set) var view: AVRoutePickerView?

	public init(view: ParentObject) {
		self.view = view
		super.init(parentObject: view, delegateProxy: RxAVRoutePickerViewDelegateProxy.self)
	}

	static func registerKnownImplementations() {
		register { RxAVRoutePickerViewDelegateProxy(view: $0) }
	}
}

@available(iOS 11.0, tvOS 11.0, *)
extension Reactive where Base: AVRoutePickerView {

	public var delegate: DelegateProxy<AVRoutePickerView, AVRoutePickerViewDelegate> {
		return RxAVRoutePickerViewDelegateProxy.proxy(for: base)
	}

	public var willBeginPresentingRoutes: Observable<Void> {
		return delegate.methodInvoked(#selector(AVRoutePickerViewDelegate.routePickerViewWillBeginPresentingRoutes(_:)))
			.map { _ in () }
	}

	public var didEndPresentingRoutes: Observable<Void> {
		return delegate.methodInvoked(#selector(AVRoutePickerViewDelegate.routePickerViewDidEndPresentingRoutes(_:)))
			.map { _ in () }
	}
}

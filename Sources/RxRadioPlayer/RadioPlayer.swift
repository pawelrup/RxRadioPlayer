//
//  RadioPlayer.swift
//  RxRadioPlayer
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import AVFoundation
import RxSwift
import RxCocoa
import RxAVFoundation

public protocol RadioPlayerType {
	var radioURL: URL? { get set }
	var isAutoPlay: Bool { get set }

	var state: Observable<RadioPlayerState> { get }
	var playbackState: Observable<RadioPlayerPlaybackState> { get }
	var isPlaying: Observable<Bool> { get }
	var metadata: Observable<Metadata?> { get }
	var rate: Observable<Float?> { get }

	func play()
	func pause()
	func stop()
	func togglePlaying()
}

open class RadioPlayer: RadioPlayerType {

	// MARK: - Private properties

	/// AVPlayer
	private var player: AVPlayer?

	/// Last player item
	private var lastPlayerItem: AVPlayerItem?

	/// Default player item
	private var playerItem: AVPlayerItem? {
		didSet {
			playerItemDidChange()
		}
	}

	private let stateSubject = BehaviorSubject<RadioPlayerState>(value: .urlNotSet)
	private let playbackStateSubject = BehaviorSubject<RadioPlayerPlaybackState>(value: .stopped)
	private let isPlayingSubject = BehaviorSubject<Bool>(value: false)
	private let metadataSubject = BehaviorSubject<Metadata?>(value: nil)
	private let rateSubject = BehaviorSubject<Float?>(value: nil)
	private let areHeadphonesConnectedSubject = BehaviorSubject<Bool>(value: false)

	private var avPlayerItemDisposables = DisposeBag()
	private var disposeBag = DisposeBag()

	// MARK: - Properties

	public let state: Observable<RadioPlayerState>
	public let playbackState: Observable<RadioPlayerPlaybackState>
	public let isPlaying: Observable<Bool>
	public let metadata: Observable<Metadata?>
	public let rate: Observable<Float?>
	public let areHeadphonesConnected: Observable<Bool>

	/// The player current radio URL
	open var radioURL: URL? {
		didSet {
			radioURLDidChange(with: radioURL)
		}
	}

	/// The player starts playing when the radioURL property gets set. (default == true)
	open var isAutoPlay = true

	public init(audioSession: AVAudioSession, radioURL: URL? = nil, isAutoPlay: Bool = true) {

		self.state = stateSubject.asObservable()
		self.playbackState = playbackStateSubject.asObservable()
		self.isPlaying = isPlayingSubject.asObservable()
		self.metadata = metadataSubject.asObservable()
		self.rate = rateSubject.asObservable()
		self.areHeadphonesConnected = areHeadphonesConnectedSubject.asObservable()

		self.isAutoPlay = isAutoPlay
		self.radioURL = radioURL

		// Check for headphones
		checkHeadphonesConnection(outputs: audioSession.currentRoute.outputs)

		setObservables(to: audioSession)

		playbackState
			.map { $0 == .playing }
			.subscribe(isPlayingSubject)
			.disposed(by: disposeBag)
	}

	deinit {
		resetPlayer()
	}

	// MARK: - Private helpers

	private func resetPlayer() {
		stop()
		playerItem = nil
		lastPlayerItem = nil
		player = nil
	}

	private func radioURLDidChange(with url: URL?) {
		resetPlayer()
		guard let url = url else {
			stateSubject.onNext(.urlNotSet)
			return
		}

		stateSubject.onNext(.loading)

		preparePlayer(with: AVAsset(url: url)) { [weak self] (success: Bool, asset: AVAsset?) in
			guard success, let asset = asset else {
				self?.resetPlayer()
				self?.stateSubject.onNext(.error)
				return
			}
			self?.setupPlayer(with: asset)
		}
	}

	private func setupPlayer(with asset: AVAsset) {
		if player == nil {
			player = AVPlayer()
		}
		playerItem = AVPlayerItem(asset: asset)
	}

	/// Prepare the player from the passed AVAsset
	private func preparePlayer(with asset: AVAsset?, completionHandler: @escaping (_ isPlayable: Bool, _ asset: AVAsset?) -> Void) {
		guard let asset = asset else {
			completionHandler(false, nil)
			return
		}

		let requestedKey = ["playable"]

		asset.loadValuesAsynchronously(forKeys: requestedKey) {

			DispatchQueue.main.async {
				var error: NSError?

				let keyStatus = asset.statusOfValue(forKey: "playable", error: &error)
				if keyStatus == AVKeyValueStatus.failed || !asset.isPlayable {
					completionHandler(false, nil)
					return
				}

				completionHandler(true, asset)
			}
		}
	}

	private func checkHeadphonesConnection(outputs: [AVAudioSessionPortDescription]) {
		for output in outputs where output.portType == .headphones {
			areHeadphonesConnectedSubject.onNext(true)
			break
		}
		areHeadphonesConnectedSubject.onNext(false)
	}

	private func playerItemDidChange() {
		guard lastPlayerItem != playerItem else { return }

		if lastPlayerItem != nil {
			avPlayerItemDisposables = DisposeBag()
		}

		lastPlayerItem = playerItem
		metadataSubject.onNext(nil)

		if let item = playerItem {
			setObservables(to: item)
			if isAutoPlay { play() }
		}
	}

	// MARK: - Public functions

	open func play() {
		guard let player = player else { return }
		if player.currentItem == nil, playerItem != nil {
			player.replaceCurrentItem(with: playerItem)
		}
		player.play()
		playbackStateSubject.onNext(.playing)
	}

	open func pause() {
		guard let player = player else { return }
		player.pause()
		playbackStateSubject.onNext(.paused)
	}

	open func stop() {
		guard let player = player else { return }
		player.replaceCurrentItem(with: nil)
		metadataSubject.onNext(nil)
		playbackStateSubject.onNext(.stopped)
	}

	open func togglePlaying() {
		try? isPlayingSubject.value() ? pause() : play()
	}

	// MARK: - Observing

	private func setObservables(to audioSession: AVAudioSession) {
		NotificationCenter.default.rx.notification(AVAudioSession.routeChangeNotification)
			.map { $0.userInfo }
			.map {
				let reasonRaw = $0?[AVAudioSessionRouteChangeReasonKey] as? UInt
				let previousRoute = $0?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
				return (reasonRaw, previousRoute)
			}
			.map { (reasonRaw: UInt?, previousRoute: AVAudioSessionRouteDescription?) -> (AVAudioSession.RouteChangeReason, AVAudioSessionRouteDescription?) in
				let reason: AVAudioSession.RouteChangeReason
				if let raw = reasonRaw {
					reason = AVAudioSession.RouteChangeReason(rawValue: raw) ?? .unknown
				} else {
					reason = .unknown
				}
				return (reason: reason, previousRouteDescription: previousRoute)
			}
			.subscribeOn(MainScheduler.instance)
			.subscribe(onNext: { [weak self, weak audioSession] (reason, previousRouteDescription) in
				switch reason {
				case .newDeviceAvailable:
					guard let strongSelf = self,
						let session = audioSession else { return }
					strongSelf.checkHeadphonesConnection(outputs: session.currentRoute.outputs)
				case .oldDeviceUnavailable:
					guard let strongSelf = self,
						let previousRoute = previousRouteDescription else { return }
					strongSelf.checkHeadphonesConnection(outputs: previousRoute.outputs)
					try? strongSelf.areHeadphonesConnectedSubject.value() ? () : strongSelf.pause()
				default: break
				}
			})
			.disposed(by: disposeBag)
	}

	private func setObservables(to item: AVPlayerItem) {
		let isPlaybackLikelyToKeepUp = item.rx.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
			.map { $0 ?? false }
			.share()
		let isPlaybackBufferEmpty = item.rx.observe(Bool.self, #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
			.map { $0 ?? false }
			.share()
		item.rx.observe(AVPlayerItem.Status.self, #keyPath(AVPlayerItem.status))
			.map { $0 ?? .unknown }
			.subscribe(onNext: { [weak self] (status: AVPlayerItem.Status) in
				if status == .readyToPlay {
					self?.stateSubject.onNext(.readyToPlay)
				} else if status == .failed {
					self?.stateSubject.onNext(.error)
				}
			})
			.disposed(by: avPlayerItemDisposables)
		isPlaybackBufferEmpty
			.subscribe(onNext: { [weak self] (isBufferEmpty: Bool) in
				if isBufferEmpty {
					self?.stateSubject.onNext(.loading)
				}
			})
			.disposed(by: avPlayerItemDisposables)
		isPlaybackLikelyToKeepUp
			.map { (isLikelyToKeepUp: Bool) in
				return isLikelyToKeepUp ? .loadingFinished : .loading
			}
			.bind(to: stateSubject)
			.disposed(by: avPlayerItemDisposables)
		item.rx.observe([AVMetadataItem].self, #keyPath(AVPlayerItem.timedMetadata))
			.map { $0 ?? [] }
			.map { $0.first }
			.compactMap { $0 }
			.map { RadioPlayerMetadata(metadata: $0) }
			.compactMap { $0 }
			.observeOn(MainScheduler.instance)
			.bind(to: metadataSubject)
			.disposed(by: avPlayerItemDisposables)
		Observable
			.combineLatest(isPlaybackLikelyToKeepUp, isPlaybackBufferEmpty) { (playbackLikelyToKeepUp: Bool, playbackBufferEmpty: Bool) in
				return !playbackLikelyToKeepUp && playbackBufferEmpty
			}
			.filter { [weak self] (stoppedUnexpectedly: Bool) in
				guard let `self` = self,
					let isPlaying = try? self.isPlayingSubject.value() else { return false }
				return stoppedUnexpectedly && isPlaying
			}
			.subscribe(onNext: { [weak self] _ in
				self?.stop()
				self?.play()
			})
			.disposed(by: avPlayerItemDisposables)
	}
}

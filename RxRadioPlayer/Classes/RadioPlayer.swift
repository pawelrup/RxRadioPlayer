//
//  RadioPlayer.swift
//  RxRadioPlayer
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import AVFoundation
import RxSwift
import MediaPlayer

public protocol RadioPlayerType {
	var radioURL: URL? { get set }
	var isAutoPlay: Bool { get set }

	var infoCenterData: AnyObserver<RadioPlayerInfoCenterData> { get }

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

	private let infoCenterDataSubject = PublishSubject<RadioPlayerInfoCenterData>()
	private let stateSubject = BehaviorSubject<RadioPlayerState>(value: .urlNotSet)
	private let playbackStateSubject = BehaviorSubject<RadioPlayerPlaybackState>(value: .stopped)
	private let isPlayingSubject = BehaviorSubject<Bool>(value: false)
	private let metadataSubject = BehaviorSubject<Metadata?>(value: nil)
	private let rateSubject = BehaviorSubject<Float?>(value: nil)
	private let areHeadphonesConnectedSubject = BehaviorSubject<Bool>(value: false)

	private var avPlayerItemDisposables = DisposeBag()
	private var disposeBag = DisposeBag()

	// MARK: - Properties

	public let infoCenterData: AnyObserver<RadioPlayerInfoCenterData>
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

	public init(radioURL: URL? = nil, isAutoPlay: Bool = true) {
		self.infoCenterData = infoCenterDataSubject.asObserver()

		self.state = stateSubject.asObservable()
		self.playbackState = playbackStateSubject
		self.isPlaying = isPlayingSubject
		self.metadata = metadataSubject
		self.rate = rateSubject
		self.areHeadphonesConnected = areHeadphonesConnectedSubject

		self.isAutoPlay = isAutoPlay
		self.radioURL = radioURL

		let audioSession = AVAudioSession.sharedInstance()
		var options: AVAudioSession.CategoryOptions = []
		#if os(iOS)
		options = [.defaultToSpeaker, .allowBluetooth, .allowAirPlay]
		#elseif os(tvOS)
		options = []
		#endif
		try? audioSession.setCategory(.playback, mode: .default, options: options)
		try? audioSession.setActive(true)

		setupRemoteCommandCenter()

		// Check for headphones
		checkHeadphonesConnection(outputs: audioSession.currentRoute.outputs)

		setObservables(to: audioSession)

		playbackState
			.map { $0 == .playing }
			.subscribe(isPlayingSubject)
			.disposed(by: disposeBag)
		infoCenterDataSubject
			.subscribe(onNext: { [unowned self] (infoCenterData: RadioPlayerInfoCenterData) in
				self.setNowPlayingInfo(withArtist: infoCenterData.artist, title: infoCenterData.title, andImage: infoCenterData.image)
			})
			.disposed(by: disposeBag)
	}

	deinit {
		resetPlayer()
		let remoteCommandCenter = MPRemoteCommandCenter.shared()
		remoteCommandCenter.togglePlayPauseCommand.removeTarget(self)
		remoteCommandCenter.playCommand.removeTarget(self)
		remoteCommandCenter.pauseCommand.removeTarget(self)
		remoteCommandCenter.stopCommand.removeTarget(self)
	}

	// MARK: - Private helpers

	private func setupRemoteCommandCenter() {
		let remoteCommandCenter = MPRemoteCommandCenter.shared()
		remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
		remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
			self?.togglePlaying()
			return .success
		}
		remoteCommandCenter.playCommand.isEnabled = true
		remoteCommandCenter.playCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
			self?.play()
			return .success
		}
		remoteCommandCenter.pauseCommand.isEnabled = true
		remoteCommandCenter.pauseCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
			self?.pause()
			return .success
		}
		remoteCommandCenter.stopCommand.isEnabled = true
		remoteCommandCenter.stopCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
			self?.stop()
			return .success
		}
	}

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

	// MARK: - Info Center

	public func setNowPlayingInfo(withArtist artist: String, title: String, andImage image: UIImage) {
		let coverItem = MPMediaItemArtwork(boundsSize: image.size) { (_: CGSize) -> UIImage in
				return image
			}
		var nowPlayingInfo = [String: Any]()
		nowPlayingInfo[MPMediaItemPropertyArtist] = artist
		nowPlayingInfo[MPMediaItemPropertyTitle] = title
		nowPlayingInfo[MPMediaItemPropertyArtwork] = coverItem
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
	}

	// MARK: - Observing

	private func setObservables(to audioSession: AVAudioSession) {
		audioSession.rx.routeChange
			.subscribeOn(MainScheduler.instance)
			.subscribe(onNext: { [weak self, weak audioSession] (routeChangeInfo: AVAudioSessionRouteChangeInfo) in
				switch routeChangeInfo.reason {
				case .newDeviceAvailable:
					guard let strongSelf = self,
						let session = audioSession else { return }
					strongSelf.checkHeadphonesConnection(outputs: session.currentRoute.outputs)
				case .oldDeviceUnavailable:
					guard let strongSelf = self,
						let previousRoute = routeChangeInfo.previousRouteDescription else { return }
					strongSelf.checkHeadphonesConnection(outputs: previousRoute.outputs)
					try? strongSelf.areHeadphonesConnectedSubject.value() ? () : strongSelf.pause()
				default: break
				}
			})
			.disposed(by: disposeBag)
	}

	private func setObservables(to item: AVPlayerItem) {
		item.rx.status
			.subscribe(onNext: { [weak self] (status: AVPlayerItem.Status) in
				if status == .readyToPlay {
					self?.stateSubject.onNext(.readyToPlay)
				} else if status == .failed {
					self?.stateSubject.onNext(.error)
				}
			})
			.disposed(by: avPlayerItemDisposables)
		item.rx.playbackBufferEmpty
			.subscribe(onNext: { [weak self] (isBufferEmpty: Bool) in
				if isBufferEmpty {
					self?.stateSubject.onNext(.loading)
				}
			})
			.disposed(by: avPlayerItemDisposables)
		item.rx.playbackLikelyToKeepUp
			.map { (isLikelyToKeepUp: Bool) in
				return isLikelyToKeepUp ? .loadingFinished : .loading
			}
			.bind(to: stateSubject)
			.disposed(by: avPlayerItemDisposables)
		item.rx.timedMetadata
			.map { $0.first }
			.compactMap { $0 }
			.map { RadioPlayerMetadata(metadata: $0) }
			.compactMap { $0 }
			.observeOn(MainScheduler.instance)
			.bind(to: metadataSubject)
			.disposed(by: avPlayerItemDisposables)
		Observable
			.combineLatest(item.rx.playbackLikelyToKeepUp, item.rx.playbackBufferEmpty) { (playbackLikelyToKeepUp: Bool, playbackBufferEmpty: Bool) in
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

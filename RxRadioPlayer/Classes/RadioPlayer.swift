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
import Action

open class RadioPlayer: NSObject {

	private (set) var metadataLoader: RadioPlayerMetadataLoaderType = RadioPlayerMetadataLoader()
	public static let shared = RadioPlayer()

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

	private var avPlayerItemDisposables = DisposeBag()
	private var metadataTimerDisposables = DisposeBag()
	private var disposeBag = DisposeBag()

	// MARK: - Properties
	
	public let infoCenterData: AnyObserver<RadioPlayerInfoCenterData>

	public let state = BehaviorSubject<RadioPlayerState>(value: .urlNotSet)
	public let playbackState = BehaviorSubject<RadioPlayerPlaybackState>(value: .stopped)
	public let isPlaying = BehaviorSubject<Bool>(value: false)
	public let metadata = BehaviorSubject<RadioPlayerMetadata?>(value: nil)
	public let rate = BehaviorSubject<Float?>(value: nil)

	/// Check for headphones, used to handle audio route change
	public let areHeadphonesConnected = BehaviorSubject<Bool>(value: false)

	/// The player current radio URL
	open var radioURL: URL? {
		didSet {
			radioURLDidChange(with: radioURL)
			setMetadataLoader(with: radioURL)
		}
	}

	/// The player starts playing when the radioURL property gets set. (default == true)
	open var isAutoPlay = true

	private override init() {
		let infoCenterData = PublishSubject<RadioPlayerInfoCenterData>()
		self.infoCenterData = infoCenterData.asObserver()
		super.init()

		let audioSession = AVAudioSession.sharedInstance()
		var options: AVAudioSession.CategoryOptions = []
		#if os(iOS)
		options = [.defaultToSpeaker, .allowBluetooth]
		#endif
		try? audioSession.setCategory(.playback, mode: .default, options: options)
		try? audioSession.setActive(true)

		let remoteCommandCenter = MPRemoteCommandCenter.shared()
		remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
		remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] (_: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
			self?.togglePlaying()
			return .success
		}
		remoteCommandCenter.playCommand.isEnabled = true
		remoteCommandCenter.playCommand.addTarget { [weak self] (_: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
			self?.play()
			return .success
		}
		remoteCommandCenter.pauseCommand.isEnabled = true
		remoteCommandCenter.pauseCommand.addTarget { [weak self] (_: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
			self?.pause()
			return .success
		}
		remoteCommandCenter.stopCommand.isEnabled = true
		remoteCommandCenter.stopCommand.addTarget { [weak self] (_: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
			self?.stop()
			return .success
		}

		// Check for headphones
		checkHeadphonesConnection(outputs: audioSession.currentRoute.outputs)

		playbackState
			.map { $0 == .playing }
			.subscribe(isPlaying)
			.disposed(by: disposeBag)
		setObservables(to: audioSession)
		
		Observable.of(infoCenterData)
			.merge()
			.subscribe(onNext: { [unowned self] (infoCenterData: RadioPlayerInfoCenterData) in
				self.setNowPlayingInfo(withArtist: infoCenterData.artist, title: infoCenterData.title, andImage: infoCenterData.image)
			})
			.disposed(by: disposeBag)
	}

	convenience init(radioURL: URL, isAutoPlay: Bool = true, metadataLoader: RadioPlayerMetadataLoaderType? = nil) {
		self.init()
		self.isAutoPlay = isAutoPlay
		self.radioURL = radioURL
		self.metadataLoader = metadataLoader ?? RadioPlayerMetadataLoader()
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

	private func resetPlayer() {
		stop()
		playerItem = nil
		lastPlayerItem = nil
		player = nil
	}

	private func radioURLDidChange(with url: URL?) {
		resetPlayer()
		guard let url = url else {
			state.onNext(.urlNotSet)
			return
		}

		state.onNext(.loading)

		preparePlayer(with: AVAsset(url: url)) { [weak self] (success: Bool, asset: AVAsset?) in
			guard success, let asset = asset else {
				self?.resetPlayer()
				self?.state.onNext(.error)
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
			areHeadphonesConnected.onNext(true)
			break
		}
		areHeadphonesConnected.onNext(false)
	}

	// MARK: - Public functions

	open func play() {
		guard let player = player else { return }
		if player.currentItem == nil, playerItem != nil {
			player.replaceCurrentItem(with: playerItem)
		}
		player.play()
		playbackState.onNext(.playing)
	}

	open func pause() {
		guard let player = player else { return }
		player.pause()
		playbackState.onNext(.paused)
	}

	open func stop() {
		guard let player = player else { return }
		player.replaceCurrentItem(with: nil)
		metadata.onNext(nil)
		playbackState.onNext(.stopped)
	}

	open func togglePlaying() {
		try? isPlaying.value() ? pause() : play()
	}

	private func playerItemDidChange() {
		guard lastPlayerItem != playerItem else { return }

		if lastPlayerItem != nil {
			avPlayerItemDisposables = DisposeBag()
		}

		lastPlayerItem = playerItem
		metadata.onNext(nil)

		if let item = playerItem {
			setObservables(to: item)
			if isAutoPlay { play() }
		}
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

	private func setMetadataLoader(with url: URL?) {
		metadataTimerDisposables = DisposeBag()
		guard let url = url else { return }
		isPlaying
			.flatMapLatest { isPlaying in
				isPlaying ? .empty() : Observable<Int>.interval(5, scheduler: MainScheduler.instance)
			}
			.withLatestFrom(metadataLoader.load(from: url))
			.subscribe(onNext: { [weak self] (metadata: RadioPlayerMetadata) in
				self?.metadata.onNext(metadata)
			})
			.disposed(by: metadataTimerDisposables)
	}

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
					try? strongSelf.areHeadphonesConnected.value() ? () : strongSelf.pause()
				default: break
				}
			})
			.disposed(by: disposeBag)
	}

	private func setObservables(to item: AVPlayerItem) {
		item.rx.status
			.subscribe(onNext: { [weak self] (status: AVPlayerItem.Status) in
				if status == .readyToPlay {
					self?.state.onNext(.readyToPlay)
				} else if status == .failed {
					self?.state.onNext(.error)
				}
			})
			.disposed(by: avPlayerItemDisposables)
		item.rx.playbackBufferEmpty
			.subscribe(onNext: { [weak self] (isBufferEmpty: Bool) in
				if isBufferEmpty {
					self?.state.onNext(.loading)
				}
			})
			.disposed(by: avPlayerItemDisposables)
		item.rx.playbackLikelyToKeepUp
			.subscribe(onNext: { [weak self] (isLikelyToKeepUp: Bool) in
				let state: RadioPlayerState = isLikelyToKeepUp ? .loadingFinished : .loading
				self?.state.onNext(state)
			})
			.disposed(by: avPlayerItemDisposables)
		item.rx.timedMetadata
			.map { $0.first }
			.unwrap()
			.map { RadioPlayerMetadata(metadata: $0) }
			.unwrap()
			.subscribe(onNext: { [weak self] (metadata: RadioPlayerMetadata) in
				guard let strongSelf = self else { return }
				strongSelf.metadata.onNext(metadata)
			})
			.disposed(by: avPlayerItemDisposables)
		Observable
			.combineLatest(item.rx.playbackLikelyToKeepUp, item.rx.playbackBufferEmpty) { (playbackLikelyToKeepUp: Bool, playbackBufferEmpty: Bool) in
				return !playbackLikelyToKeepUp && playbackBufferEmpty
			}
			.filter { [weak self] (stoppedUnexpectedly: Bool) in
				guard let `self` = self,
					let isPlaying = try? self.isPlaying.value() else { return false }
				return stoppedUnexpectedly && isPlaying
			}
			.subscribe(onNext: { [weak self] _ in
				self?.stop()
				self?.play()
			})
			.disposed(by: avPlayerItemDisposables)
	}
}

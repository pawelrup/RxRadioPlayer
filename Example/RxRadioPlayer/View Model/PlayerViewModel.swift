//
//  PlayerViewModel.swift
//  HRnew
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import RxSwift
import RxSwiftExt
import RxRadioPlayer

class PlayerViewModel {
	let sceneCoordinator: SceneCoordinatorType
	
	private let coverLoader = CoverLoader()
	private let disposeBag = DisposeBag()
	
	private (set) var metadata = BehaviorSubject<Metadata>(value: .empty)
	private (set) var playbackState = BehaviorSubject<RadioPlayerPlaybackState>(value: .stopped)
	private (set) var isLoading = BehaviorSubject<Bool>(value: false)
	
	init(sceneCoordinator: SceneCoordinatorType) {
		self.sceneCoordinator = sceneCoordinator
		RadioPlayer.shared.isAutoPlay = false
		// swiftlint:disable:next force_https
		RadioPlayer.shared.radioURL = URL(string: "http://radiointernetowe.net:7818")
		bindOutput()
	}
	
	private func bindOutput() {
		RadioPlayer.shared.metadata
			.unwrap()
			.distinctUntilChanged()
			.flatMap { Observable.from(optional: $0) }
			.flatMap { [unowned self] (meta) in
				return self.coverLoader
					.loadCover(for: URL(string: "http://i0.kym-cdn.com/entries/icons/original/000/004/815/lologuy.jpg")!)
					.map { (image: UIImage?) -> Cover in
						if let image = image {
							return Cover(image: image)
						}
						return .default
					}
					.map { Metadata(radioPlayerMetadata: meta, cover: $0) }
			}
			.do(onNext: { (metadata: Metadata) in
				RadioPlayer.shared.setNowPlayingInfo(withArtist: metadata.artist, title: metadata.title, andImage: metadata.cover.infoCenterImage)
			})
			.subscribe(metadata)
			.disposed(by: disposeBag)
		RadioPlayer.shared.playbackState
			.subscribe(playbackState)
			.disposed(by: disposeBag)
		Observable.combineLatest(RadioPlayer.shared.state, RadioPlayer.shared.playbackState)
			.map { (state: RadioPlayerState, playbackState: RadioPlayerPlaybackState) in
				return state == .loading && playbackState == .playing
			}
			.subscribe(isLoading)
			.disposed(by: disposeBag)
	}
	
	func togglePlaying() {
		RadioPlayer.shared.togglePlaying()
	}
}

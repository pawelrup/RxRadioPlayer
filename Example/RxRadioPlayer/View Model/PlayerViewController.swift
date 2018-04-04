//
//  ViewController.swift
//  HRnew
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt
import RxRadioPlayer

class PlayerViewController: UIViewController, BindableType {

	@IBOutlet private weak var artistLabel: UILabel!
	@IBOutlet private weak var titleLabel: UILabel!
	@IBOutlet private weak var playButton: UIButton!
	@IBOutlet private weak var imageView: UIImageView!
	@IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
	
	var viewModel: PlayerViewModel!
	
	private let disposeBag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	func bindViewModel() {
		viewModel.metadata
			.map { $0.artist }
			.bind(to: artistLabel.rx.text)
			.disposed(by: disposeBag)
		viewModel.metadata
			.map { $0.title }
			.bind(to: titleLabel.rx.text)
			.disposed(by: disposeBag)
		viewModel.metadata
			.map { $0.cover.image }
			.bind(to: imageView.rx.image)
			.disposed(by: disposeBag)
		
		viewModel.isLoading
			.bind(to: activityIndicatorView.rx.isAnimating)
			.disposed(by: disposeBag)
		viewModel.isLoading
			.bind(to: playButton.rx.isHidden)
			.disposed(by: disposeBag)
		
		viewModel.playbackState
			.subscribe(onNext: { [weak self] (playbackState: RadioPlayerPlaybackState) in
				self?.playButton.setTitle(playbackState.description, for: .normal)
			})
			.disposed(by: disposeBag)
		
		playButton.rx.controlEvent(.touchUpInside)
			.subscribe(onNext: { [weak self] in
				self?.viewModel.togglePlaying()
			})
			.disposed(by: disposeBag)
	}
}

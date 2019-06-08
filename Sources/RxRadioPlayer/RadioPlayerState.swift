//
//  RadioPlayerState.swift
//  RxRadioPlayer
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation

public enum RadioPlayerState: Int {
	
	/// URL not set
	case urlNotSet
	
	/// Player is ready to play
	case readyToPlay
	
	/// Player is loading
	case loading
	
	/// The loading has finished
	case loadingFinished
	
	/// Error with playing
	case error
	
	/// Return a readable description
	public var description: String {
		switch self {
		case .urlNotSet: return "URL is not set"
		case .readyToPlay: return "Ready to play"
		case .loading: return "Loading"
		case .loadingFinished: return "Loading finished"
		case .error: return "Error"
		}
	}
}

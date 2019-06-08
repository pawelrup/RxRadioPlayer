//
//  RadioPlaybackState.swift
//  RxRadioPlayer
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation

public enum RadioPlayerPlaybackState: Int {
	/// Player is playing
	case playing
	
	/// Player is paused
	case paused
	
	/// Player is stopped
	case stopped
	
	/// Return a readable description
	public var description: String {
		switch self {
		case .playing: return "Player is playing"
		case .paused: return "Player is paused"
		case .stopped: return "Player is stopped"
		}
	}
}

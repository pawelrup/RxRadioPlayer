//
//  Metadata.swift
//  HRnew
//
//  Created by Pawel Rup on 28.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import RxRadioPlayer

struct Metadata {
	static let empty = Metadata(artist: "", title: "", cover: .default)
	
	let artist: String
	let title: String
	let cover: Cover
	
	init(radioPlayerMetadata: RadioPlayerMetadata, cover: Cover) {
		self.artist = radioPlayerMetadata.artist
		self.title = radioPlayerMetadata.title
		self.cover = cover
	}
	
	init(artist: String, title: String, cover: Cover) {
		self.artist = artist
		self.title = title
		self.cover = cover
	}
}

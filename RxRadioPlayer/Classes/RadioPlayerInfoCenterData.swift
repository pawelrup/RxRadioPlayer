//
//  RadioPlayerInfoCenterData.swift
//  RxRadioPlayer
//
//  Created by Pawel Rup on 04.04.2018.
//

import Foundation

public struct RadioPlayerInfoCenterData {
	public let artist: String
	public let title: String
	public let image: UIImage
	
	public init(artist: String, title: String, image: UIImage) {
		self.artist = artist
		self.title = title
		self.image = image
	}
}

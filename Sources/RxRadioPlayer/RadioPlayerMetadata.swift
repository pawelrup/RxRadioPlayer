//
//  RadioPlayerMetadata.swift
//  RxRadioPlayer
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import AVFoundation

struct RadioPlayerMetadata: Metadata {
	
	public let artist: String
	public let title: String
	
	init?(metadata: AVMetadataItem) {
		guard let encoded = RadioPlayerMetadata.encode(metadata: metadata) else { return nil }
		let (artist, title) = RadioPlayerMetadata.parse(string: encoded)
		self.artist = artist
		self.title = title
	}
	
	private static func encode(metadata: AVMetadataItem) -> String? {
		if let data = metadata.stringValue?.data(using: .isoLatin1), let encoded = String(data: data, encoding: .utf8) {
			return encoded
		} else if let data = metadata.stringValue?.data(using: .isoLatin2), let encoded = String(data: data, encoding: .utf8) {
			return encoded
		}
		return nil
	}
}

// MARK: - Equatable
extension RadioPlayerMetadata: Equatable {
	
	public static func == (lhs: RadioPlayerMetadata, rhs: RadioPlayerMetadata) -> Bool {
		return lhs.artist == rhs.artist && lhs.title == rhs.title
	}
}

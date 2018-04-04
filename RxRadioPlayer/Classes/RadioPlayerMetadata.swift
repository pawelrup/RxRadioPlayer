//
//  RadioPlayerMetadata.swift
//  RxRadioPlayer
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import AVFoundation

public struct RadioPlayerMetadata {
	
	public let artist: String
	public let title: String
	
	public init(artist: String, title: String) {
		self.artist = artist
		self.title = title
	}
	
	init(string: String) {
		let (artist, title) = RadioPlayerMetadata.parse(string: string)
		self.artist = artist
		self.title = title
	}
	
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
	
	private static func parse(string: String) -> (String, String) {
		var str = string.replacingOccurrences(of: "_", with: " ")
		
		if let startRange = str.range(of: "<body>"), let endRange = str.range(of: "</body>") {
			str = String(str[startRange.upperBound..<endRange.lowerBound])
			var arr = str.components(separatedBy: ",")
			var string = ""
			if arr.count <= 7 {
				string = arr[arr.count-1]
			} else {
				string = arr[6]
				for index in 7 ..< arr.count {
					string += ",\(arr[index])"
				}
			}
			str = string
		}
		if let range = str.range(of: " - ") {
			let artistIndex = str.index(str.startIndex, offsetBy: str.distance(from: str.startIndex, to: range.lowerBound))
			let artist = String(str[..<artistIndex])
			let titleIndex = str.index(str.startIndex, offsetBy: str.distance(from: str.startIndex, to: range.lowerBound) + 3)
			let title = String(str[titleIndex...])
			return (artist, title)
		} else {
			return ("", str)
		}
	}
}

// MARK: - Equatable
extension RadioPlayerMetadata: Equatable {
	
	public static func == (lhs: RadioPlayerMetadata, rhs: RadioPlayerMetadata) -> Bool {
		return lhs.artist == rhs.artist && lhs.title == rhs.title
	}
}

//
//  Metadata.swift
//  Pods-Houseradio
//
//  Created by Pawel Rup on 14/04/2019.
//

import Foundation

public protocol Metadata {
	var artist: String { get }
	var title: String { get }
}

extension Metadata {

	public static func parse(string: String) -> (String, String) {
		let string = string.replacingOccurrences(of: "_", with: " ")
		if let range = string.range(of: " - ") {
			let artistIndex = string.index(string.startIndex, offsetBy: string.distance(from: string.startIndex, to: range.lowerBound))
			let artist = String(string[..<artistIndex])
			let titleIndex = string.index(string.startIndex, offsetBy: string.distance(from: string.startIndex, to: range.lowerBound) + 3)
			let title = String(string[titleIndex...])
			return (artist, title)
		} else {
			return ("", string)
		}
	}
}

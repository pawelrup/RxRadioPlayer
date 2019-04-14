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

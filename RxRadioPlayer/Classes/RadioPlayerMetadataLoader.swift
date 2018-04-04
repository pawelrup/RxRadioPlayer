//
//  RadioPlayerMetadataDownloader.swift
//  RxRadioPlayer
//
//  Created by Pawel Rup on 27.03.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import Foundation
import RxSwift
import RxSwiftExt

protocol RadioPlayerMetadataLoaderType {
	func load(from url: URL) -> Observable<RadioPlayerMetadata>
}

class RadioPlayerMetadataLoader: RadioPlayerMetadataLoaderType {
	
	func load(from url: URL) -> Observable<RadioPlayerMetadata> {
		let url = url.appendingPathComponent("7.html")
		var request = URLRequest(url: url)
		request.setValue("Mozilla/1.0 SHOUTcast example", forHTTPHeaderField: "user-agent")
		return URLSession.shared.rx.data(request: request)
			.map { (data: Data) in
				return String(data: data, encoding: .utf8)
			}
			.unwrap()
			.map { RadioPlayerMetadata(string: $0) }
			.catchError({ (error) -> Observable<RadioPlayerMetadata> in
				let errorMetadata = RadioPlayerMetadata(artist: "Connection failed.", title: error.localizedDescription)
				return Observable.just(errorMetadata)
			})
	}
}

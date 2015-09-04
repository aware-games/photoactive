//
//  AsynServerPost.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 05/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import Foundation

class AsyncServerPost : SyncServerPost {
	override func sendJSON(json: JSON) {
		let qualityOfServiceClass = QOS_CLASS_BACKGROUND // swift 1.2+
//		let qualityOfServiceClass = Int(QOS_CLASS_BACKGROUND.value) // pre swift 1.2
		let backgrundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
		dispatch_async(backgrundQueue, {
			super.sendJSON(json)
		})
	}
}
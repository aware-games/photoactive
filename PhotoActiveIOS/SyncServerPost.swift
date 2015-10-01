//
//  SyncServerPost.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 04/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit

extension String {
    func split(splitter: String) -> Array<String> {
        let regEx = try? NSRegularExpression(pattern: splitter, options: NSRegularExpressionOptions())
        let stop = "<SomeStringThatYouDoNotExpectToOccurInSelf>"
        let modifiedString = regEx?.stringByReplacingMatchesInString(self, options: NSMatchingOptions(), range: NSMakeRange(0, self.characters.count), withTemplate: stop)
        return modifiedString!.componentsSeparatedByString(stop)
    }
}

class SyncServerPost : NSObject {
	let successHandler: (data: String, cookie: String?) -> Void
	let errorHandler: (errorCode: Int, data: String) -> Void
    let url: String
    var json: JSON?
    var cookie: String?
    
	init(url: String, successHandler: (data: String, cookie: String?) -> Void, errorHandler: (errorCode: Int, data: String) -> Void) {
        self.url = url
		self.successHandler = successHandler
		self.errorHandler = errorHandler
    }
    
    init(url: String, json: JSON, successHandler: (data: String, cookie: String?) -> Void, errorHandler: (errorCode: Int, data: String) -> Void) {
        self.url = url
        self.json = json
		self.successHandler = successHandler
		self.errorHandler = errorHandler
    }
    
    init(url: String, json: JSON, cookie: String, successHandler: (data: String, cookie: String?) -> Void, errorHandler: (errorCode: Int, data: String) -> Void) {
        self.url = url
        self.json = json
        self.cookie = cookie
		self.successHandler = successHandler
		self.errorHandler = errorHandler
    }
    
    func execute() {
        if json != nil {
            sendJSON(json!)
        }
    }
    
    func sendJSON(json: JSON) {
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let postData: String = json.rawString(NSUTF8StringEncoding, options: [])!
        let request = NSMutableURLRequest(URL: NSURL(string: self.url)!)
		let semaphore = dispatch_semaphore_create(0)

        request.HTTPMethod = POST_METHOD
        request.setValue(JSON_MIME_TYPE, forHTTPHeaderField: CONTENT_TYPE)
        request.HTTPBody = postData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

		let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
			data, response, error in

			if error != nil {
				self.errorHandler(errorCode: error!.code, data: error!.localizedDescription)
				UIApplication.sharedApplication().networkActivityIndicatorVisible = false
				return
			}

			let response = response as! NSHTTPURLResponse
			let ninjaCookie = SyncServerPost.getNinjaCookieFromResponse(response)
			let responseString = SyncServerPost.convertResponseDataToString(data!)

			if response.statusCode == OK {
				self.successHandler(data: responseString, cookie: ninjaCookie)
			}
			else {
				self.errorHandler(errorCode: response.statusCode, data: responseString)
			}
			dispatch_semaphore_signal(semaphore)
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
		}
		task.resume()
		dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
    class func convertResponseDataToString(data: NSData) -> String {
        let str = NSString(data: data, encoding: NSUTF8StringEncoding)
        return str as! String
    }
	
    class func getNinjaCookieFromResponse(response: NSHTTPURLResponse) -> String? {
        for (headerName, headerContent) in response.allHeaderFields {
            if headerName == GET_COOKIES_HEADER {
                if headerContent is String {
                    let cookies = (headerContent as! String).split(SEMI_COLON)
                    for cookie in cookies {
                        let cookieData = cookie.split(EQUALS_SIGN)
                        let cookieName = cookieData[0]
                        if cookieName == NINJA_COOKIE_NAME {
                            return cookie
                        }
                    }
                }
            }
        }
        return nil
    }
}
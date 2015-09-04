//
//  NSDateExt.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 03/09/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import Foundation

extension NSDate {
	func isGreaterThanDate(dateToCompare : NSDate) -> Bool {
		var isGreater = false

		if compare(dateToCompare) == NSComparisonResult.OrderedDescending {
			isGreater = true
		}

		return isGreater
	}

	func isLessThanDate(dateToCompare : NSDate) -> Bool {
		var isLess = false

		if compare(dateToCompare) == NSComparisonResult.OrderedAscending {
			isLess = true
		}

		return isLess
	}

	func addDays(daysToAdd : Int) -> NSDate {
		let secondsInDays : NSTimeInterval = Double(daysToAdd) * 60 * 60 * 24
		let dateWithDaysAdded : NSDate = dateByAddingTimeInterval(secondsInDays)

		return dateWithDaysAdded
	}

	func addHours(hoursToAdd : Int) -> NSDate {
		let secondsInHours : NSTimeInterval = Double(hoursToAdd) * 60 * 60
		let dateWithHoursAdded : NSDate = dateByAddingTimeInterval(secondsInHours)

		return dateWithHoursAdded
	}

	func addYears(yearsToAdd: Int) -> NSDate {
		let secondsInYears: NSTimeInterval = Double(yearsToAdd) * 60 * 60 * 24 * 365
		let dateWithYearsAdded: NSDate = dateByAddingTimeInterval(secondsInYears)

		return dateWithYearsAdded
	}
}
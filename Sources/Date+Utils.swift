import Foundation



internal extension Date {
	
	func lokiTimestamp() -> String {
		var dateSecondsStr = String(timeIntervalSince1970)
		
		/* If the timestamp is exactly at the epoch, we encode 0.
		 * In theory we could check only if the str is exactly "0.0", but let’s be paranoid. */
		if (dateSecondsStr.filter{ $0 != "0" && $0 != "." }).isEmpty {
			return "0"
		}
		
		/* Check if we have a decimal in the string representation of the timestamp.
		 * In theory this should _always_ be the case as Swift always put the decimal separator when encoding a Double. */
		if let decimalSeparatorIndex = dateSecondsStr.firstIndex(of: ".") {
			let nCharsAfterDecimal = dateSecondsStr.distance(from: decimalSeparatorIndex, to: dateSecondsStr.endIndex) - 1
			dateSecondsStr.remove(at: decimalSeparatorIndex)
			if nCharsAfterDecimal > 9 {
				/* Let’s remove the additional decimals we have. */
				dateSecondsStr.removeLast(nCharsAfterDecimal - 9)
			} else if nCharsAfterDecimal < 9 {
				/* Let’s add some 0s to have the correct number of decimals. */
				dateSecondsStr.append(String(repeating: "0", count: 9 - nCharsAfterDecimal))
			}
			return dateSecondsStr
		}
		
		return dateSecondsStr + "000000000"
	}
	
}

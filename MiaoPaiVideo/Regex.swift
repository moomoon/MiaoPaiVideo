//
//  Regex.swift
//  MiaoPaiVideo
//
//  Created by Phoebe Hu on 9/26/15.
//  Copyright © 2015 Phoebe Hu. All rights reserved.
//

import Foundation



import Foundation

infix operator =~ {}

func =~ (value : String, pattern : String) -> RegexMatchResult {
    let nsstr = value as NSString // we use this to access the NSString methods like .length and .substringWithRange(NSRange)
    let options : NSRegularExpressionOptions = []
    do {
        let re = try  NSRegularExpression(pattern: pattern, options: options)
        let all = NSRange(location: 0, length: nsstr.length)
        var matches : Array<String> = []
        var ranges = [NSRange]()
        re.enumerateMatchesInString(value, options: [], range: all) { (result, flags, ptr) -> Void in
            guard let result = result else { return }
            print("range = \(result.range)")
            if result.range.location + result.range.length < value.characters.count {
                ranges.append(result.range)
                let string = nsstr.substringWithRange(result.range)
                matches.append(string)
            }
        }
        return RegexMatchResult(items: matches, ranges: ranges)
    } catch {
        return RegexMatchResult(items: [], ranges: [])
    }
}



struct RegexMatchCaptureGenerator : GeneratorType {
    var items: ArraySlice<String>
    mutating func next() -> String? {
        if items.isEmpty { return nil }
        let ret = items[items.startIndex]
        items = items[1..<items.count]
        return ret
    }
}

struct RegexMatchResult : SequenceType, BooleanType {
    var items: Array<String>
    var ranges: [NSRange]
    func generate() -> RegexMatchCaptureGenerator {
        return RegexMatchCaptureGenerator(items: items[0..<items.count])
    }
    var boolValue: Bool {
        return items.count > 0
    }
    subscript (i: Int) -> String {
        return items[i]
    }
}


extension String {
    public subscript(range: Range<Int>) -> String {
        let start = startIndex.advancedBy(range.startIndex)
        let end = startIndex.advancedBy(range.endIndex)
        return self.substringWithRange(Range(start: start, end: end))
    }
    
    func replaceAll(regex: String, replacement: String) -> String {
        var rest: NSString = self as NSString
        var match = self =~ regex
        while match.ranges.count > 0 {
            print("matching range \(match.ranges[0]) length = \(rest.length)")
            rest = rest.stringByReplacingCharactersInRange(match.ranges[0], withString: replacement)
            match = rest as String  =~ regex
        }
        return rest as String
    }
}

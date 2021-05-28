import Foundation
import CoreGraphics

extension RandomAccessCollection {
    func split(maxLength: CGFloat, spacing: CGFloat, measure: (Element) -> CGFloat?) -> [Range<Index>] {
        var length: CGFloat = 0
        var result: [Range<Index>] = []
        var chunkStart = startIndex
        var chunkLength = 0
        
        for element in self {
            guard let elementLength = measure(element)
            else { break }
            let newLength = length + elementLength
            if newLength < maxLength || chunkLength == 0 {
                length = newLength + spacing
                chunkLength += 1
            } else {
                length = elementLength
                let lineEnd = index(chunkStart, offsetBy:chunkLength)
                result.append(chunkStart ..< lineEnd)
                chunkLength = 0
                chunkStart = lineEnd
            }
        }
        
        if chunkStart != endIndex {
            result.append(chunkStart ..< endIndex)
        }
        return result
    }
}

import Foundation
import CoreGraphics

struct Lines<S: RandomAccessCollection> {
    typealias Element = S.Element
    typealias Index = S.Index
    
    var elements: S
    var spacing: CGFloat
    var length: (Element) -> CGFloat
    
    func split(lengthLimit: CGFloat) -> [Range<Index>] {
        var currentLength: CGFloat = 0
        var numberOfElementsInCurrentLine = 0
        var result: [Range<Index>] = []
        var lineStart = elements.startIndex
        
        for element in elements {
            let elementLength = length(element)

            let newLength = currentLength + elementLength
            
            if newLength <= lengthLimit                 // element could safely be added to the line
                || numberOfElementsInCurrentLine == 0 { // or line is empty
                currentLength = newLength + spacing
                numberOfElementsInCurrentLine += 1
            } else {                                    // moving element to the next line
                currentLength = elementLength + spacing
                let lineEnd = elements.index(lineStart, offsetBy: numberOfElementsInCurrentLine)
                result.append(lineStart ..< lineEnd)
                numberOfElementsInCurrentLine = 1
                lineStart = lineEnd
            }
        }
        
        if lineStart != elements.endIndex {
            result.append(lineStart ..< elements.endIndex)
        }
        return result
    }
}
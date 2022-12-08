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

            let newLength = currentLength + spacing + elementLength // spacing is added before the element
            
            if newLength < lengthLimit // element could safely be added to the line
                || numberOfElementsInCurrentLine == 0 { // line is empty
                currentLength = newLength
                numberOfElementsInCurrentLine += 1 //
            } else { // moving element to the next line
                currentLength = elementLength // it is the only element in the line, no spacing needed

                let lineEnd = elements.index(lineStart, offsetBy: numberOfElementsInCurrentLine)
                result.append(lineStart ..< lineEnd)
                lineLength = 1
                lineStart = lineEnd
            }
        }
        
        if lineStart != data.endIndex {
            result.append(lineStart ..< data.endIndex)
        }
        return result
    }
}

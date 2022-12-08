import Foundation

struct Lines<S: RandomAccessCollection, Weight: AdditiveArithmetic & Comparable> {
    typealias Element = S.Element
    typealias Index = S.Index
    
    var elements: S
    var spacing: Weight
    var length: (Element) -> Weight
    
    func split(lengthLimit: Weight) -> [Range<Index>] {
        var currentLength: Weight = .zero
        var numberOfElementsInCurrentLine = 0
        var result: [Range<Index>] = []
        var lineStart = elements.startIndex
        
        for element in elements {
            let elementLength = length(element)
            let newLength = currentLength + elementLength
            
            // element could safely be added to the line
            // or line is empty
            if newLength <= lengthLimit || numberOfElementsInCurrentLine == 0 {
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

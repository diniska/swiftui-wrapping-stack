import Foundation

enum MultilineSizeComputer {
    static func aggregate<S: RandomAccessCollection>(
        elements: S,
        length: (S.Element) -> CGFloat,
        orthogonalLength: (S.Element) -> CGFloat,
        aggregateLength: (CGFloat, _ result: CGFloat) -> CGFloat,
        aggregateOrthogonalLength: (CGFloat, _ result: CGFloat) -> CGFloat
    ) -> (length: CGFloat, orthogonalLength: CGFloat) {
        elements.reduce(into: (length: CGFloat.zero, orthogonalLength: CGFloat.zero)) { result, element in
            result.length = aggregateLength(result.length, length(element))
            result.orthogonalLength = aggregateOrthogonalLength(result.orthogonalLength, orthogonalLength(element))
        }
    }
    
    static func lineSize<S: RandomAccessCollection>(
        elements: S,
        spacing: CGFloat,
        length: (S.Element) -> CGFloat,
        orthogonalLength: (S.Element) -> CGFloat
    ) -> (length: CGFloat, orthogonalLength: CGFloat) {
        gridSize(
            elements: [elements],
            spacing: spacing,
            orthogonalSpacing: 0,
            length: length,
            orthogonalLength: orthogonalLength
        )
    }
    
    static func gridSize<S: RandomAccessCollection, E: RandomAccessCollection>(
        elements: S,
        spacing: CGFloat,
        orthogonalSpacing: CGFloat,
        length: (E.Element) -> CGFloat,
        orthogonalLength: (E.Element) -> CGFloat
    ) -> (length: CGFloat, orthogonalLength: CGFloat) where S.Element == E {
        var gridSize = gridSize(
            elements: elements,
            length: { length($0) + spacing },
            orthogonalLength: orthogonalLength
        )
        
        if !elements.isEmpty {
            gridSize.length -= spacing
            gridSize.orthogonalLength += orthogonalSpacing  * CGFloat(elements.count - 1)
        }
        
        return gridSize
    }
    
    static func gridSize<S: RandomAccessCollection, E: RandomAccessCollection>(
        elements: S,
        length: (E.Element) -> CGFloat,
        orthogonalLength: (E.Element) -> CGFloat
    ) -> (length: CGFloat, orthogonalLength: CGFloat) where S.Element == E {
        aggregate(
            elements: elements.map {
                // for every line calculating total width and max height
                aggregate(
                    elements: $0,
                    length: length,
                    orthogonalLength: orthogonalLength,
                    aggregateLength: +,
                    aggregateOrthogonalLength: max
                ) as (CGFloat, CGFloat) as (lineWidth: CGFloat, lineHeight: CGFloat)
            },
            length: \.lineWidth,
            orthogonalLength: \.lineHeight,
            aggregateLength: max,
            aggregateOrthogonalLength: +
        )
    }
}

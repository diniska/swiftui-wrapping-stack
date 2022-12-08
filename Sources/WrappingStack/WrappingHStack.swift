#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 16, macOS 13, *)
public struct WrappingHStack: View {
    
    public var idealLineLength: Int?
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    
    public init(
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat,
        idealLineLength: Int? = nil
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    public var body: some View {
        WrappingHStackLayout(
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        ) {
            ForEach(0 ..< 20) { index in
                Rectangle().frame(width: 50, height: 50)
                    .overlay(Text("\(index)").foregroundColor(.white))
            }
        }
        .background(Color.gray)
    }
}

@available(iOS 16, macOS 13, *)
private struct WrappingHStackLayout: Layout {
    struct Cache {
        private(set) var dimensions: [ViewDimensions] = []
        
        mutating func invalidate() {
            dimensions = []
        }
        
        mutating func updateSizesIfNeeded(subviews: Subviews, proposal: ProposedViewSize) {
            guard dimensions.isEmpty
            else { return }
            
            dimensions = subviews.map { $0.dimensions(in: proposal) }
        }
    }
    
    static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
    
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat
    
    func makeCache(subviews: Subviews) -> Cache { .init() }
    
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.invalidate()
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache)
    -> CGSize {
        print("Proposed size \(proposal.width)x\(proposal.height)")
        
//        The zero proposal; respond with the layout’s minimum size.
//        The infinity proposal; respond with the layout’s maximum size.
//        The unspecified proposal; respond with the layout’s ideal size.
        
        cache.updateSizesIfNeeded(subviews: subviews, proposal: proposal)
        
        let dimensions = cache.dimensions
        
        if proposal.width == .zero {
            // searching for minimal width size
            let result = calculateMinWidthSize(dimensions: dimensions)
            print(result)
            return result
        } else if proposal.width == .infinity {
            // searching for minimal width size
            let result = calculateMaxWidthSize(dimensions: dimensions)
            print(result)
            return result
        }
        
        
        //FIXME:
        let proposedSize = proposal.replacingUnspecifiedDimensions(by: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        

        let lines = Lines(
            elements: subviews.indices,
            spacing: horizontalSpacing
        ) { dimensions[$0].width }.split(lengthLimit: proposedSize.width)
        
        let linesHeights = lines.lazy
            .map { dimensions[$0].lazy.map { $0.height }.max() ?? 0 }
        
        let verticalSpacing = verticalSpacing
        let horizontalSpacing = horizontalSpacing
        
        var totalHeight = linesHeights.reduce(into: 0) { totalHeight, lineHeight in
            totalHeight += lineHeight + verticalSpacing
        }
        
        var maxWidth = lines.lazy.map {
            dimensions[$0].lazy.map { $0.width }.reduce(into: 0) { width, elementWidth in
                width += elementWidth + horizontalSpacing
            }
        }.max() ?? 0
        
        if !lines.isEmpty {
            maxWidth -= horizontalSpacing
            totalHeight -= verticalSpacing
        }
        
        let computedSize = CGSize(width: maxWidth, height: totalHeight)
        
        print(lines)
        print(computedSize)
        
        return computedSize
    }
    
    private func calculateMinWidthSize(dimensions: [ViewDimensions]) -> CGSize {
        let (height, width) = calculateLineSize(
            elements: dimensions,
            spacing: verticalSpacing,
            length: \.height,
            normalLength: \.width
        )
        return CGSize(width: width, height: height)
    }
    
    private func calculateMaxWidthSize(dimensions: [ViewDimensions]) -> CGSize {
        let (width, height) = calculateLineSize(
            elements: dimensions,
            spacing: horizontalSpacing,
            length: \.width,
            normalLength: \.height
        )
        return CGSize(width: width, height: height)
    }
    
    private func calculateLineSize<S: RandomAccessCollection>(
        elements: S,
        spacing: CGFloat,
        length: (S.Element) -> CGFloat,
        normalLength: (S.Element) -> CGFloat
    ) -> (length: CGFloat, normalLength: CGFloat) {
        
        var lineSize = elements.reduce(into:(length: CGFloat.zero, normalLength: CGFloat.zero)) { result, element in
            result.length += length(element)
            
            let normalElementLength = normalLength(element)
            
            if result.normalLength < normalElementLength{
                result.normalLength = normalElementLength
            }
        }
        
        if !elements.isEmpty {
            lineSize.length += spacing * CGFloat(elements.count - 1)
        }
        
        return lineSize
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        cache.updateSizesIfNeeded(subviews: subviews, proposal: proposal)
        
        print("Placing subviews in \(bounds)")
        let horizontalSpacing = horizontalSpacing
        let verticalSpacing = verticalSpacing
        
        let minX = bounds.minX
        
        var y: CGFloat = bounds.minY
        
        let proposedSize = proposal.replacingUnspecifiedDimensions(by: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        let dimensions = cache.dimensions
        
        let lines = Lines(
            elements: subviews.indices,
            spacing: horizontalSpacing
        ) { dimensions[$0].width }
        
        lines.split(lengthLimit: proposedSize.width).forEach { line in
            var x: CGFloat = minX
            var height: CGFloat = 0
            
            line.indices.forEach { index in
                let size = cache.dimensions[index]
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + horizontalSpacing
                height = max(height, size.height)
            }
            
            y += height + verticalSpacing
        }
    }
}

@available(iOS 16, macOS 13, *)
struct WrappingHStack_Previews: PreviewProvider {
    static var previews: some View {
        WrappingHStack(horizontalSpacing: 5, verticalSpacing: 5)
    }
}

#endif

//
//  WrappingHStackLayout.swift
//  WrappingStack
//
//  Created by Denis Chaschin on 22/1/2025.
//

#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
public struct WrappingHStackLayout: Layout {
    
    public var alignment: Alignment = .center
    public var horizontalSpacing: CGFloat = 0
    public var verticalSpacing: CGFloat = 0
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var dimensions: [Subviews.Index: ViewDimensions] = [:]
        
        let lines = IndexedLines(elements: subviews, spacing: horizontalSpacing) { index, element in
            let size = element.dimensions(in: proposal)
            dimensions[index] = size
            return size.width
        }
        
        let maxWidth = proposal.replacingUnspecifiedDimensions(by: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .zero)).width
        
        let splitted = lines.split(lengthLimit: maxWidth)
        
        guard !splitted.isEmpty
        else { return .zero }
        
        var fittedSize = splitted.reduce(into: CGSize.zero) { size, line in
            guard !line.isEmpty
            else { return }
            
            let lineSize = line.reduce(into: CGSize.zero) { lineSize, index in
                guard let dimension = dimensions[index]
                else { return }
                
                lineSize.width += dimension.width
                lineSize.height = max(lineSize.height, dimension.height)
            }
            size.width = max(size.width, lineSize.width + horizontalSpacing * CGFloat(line.count - 1))
            size.height += lineSize.height
        }
        
        fittedSize.height += verticalSpacing * CGFloat(splitted.count - 1)
        
        return fittedSize
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var dimensions: [Subviews.Index: ViewDimensions] = [:]
        
        let lines = IndexedLines(elements: subviews, spacing: horizontalSpacing) { index, element in
            let size = element.dimensions(in: proposal)
            dimensions[index] = size
            return size.width
        }
        
        let maxWidth = proposal.replacingUnspecifiedDimensions(by: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .zero)).width
        
        let splitted = lines.split(lengthLimit: maxWidth)
        
        let lineHeights: [CGFloat] = splitted.reduce(into: []) { heights, line in
            heights.append(line.lazy.map { dimensions[$0]?.height ?? 0 }.max() ?? 0)
        }
        let lineWidths: [CGFloat] = splitted.reduce(into: []) { widths, line in
            widths.append(line.lazy.map { dimensions[$0]?.width ?? 0 }.reduce(0, +) + CGFloat(line.count - 1) * horizontalSpacing)
        }
        
        var y: CGFloat = bounds.minY
        
        let alignVertically: (_ lineHeight: CGFloat, _ elementHeight: CGFloat) -> CGFloat
        
        switch alignment.vertical {
        case .top: alignVertically = { _, elementHeight in 0 }
        case .bottom: alignVertically = { lineHeight, elementHeight in lineHeight - elementHeight }
        default: alignVertically = { lineHeight, elementHeight in (lineHeight - elementHeight) / 2 }
            // TODO: support all other cases
        }
        
        let alignHorizontally: (_ lineWidth: CGFloat, _ x: CGFloat) -> CGFloat
        
        switch alignment.horizontal {
        case .leading: alignHorizontally = { _, x in x }
        case .trailing: alignHorizontally = { lineWidth, x in bounds.maxX - lineWidth + x }
        default: alignHorizontally = { lineWidth, x in x + (bounds.maxX - lineWidth) / 2 }
            // TODO: support all other cases
        }
        
        for (lineIndex, line) in splitted.enumerated() {
            var x: CGFloat = bounds.minX
            var height: CGFloat = 0
            for index in line {
                guard let dimension = dimensions[index]
                else { continue }
                
                let lineHeight = lineHeights[lineIndex]
                let lineWidth = lineWidths[lineIndex]
                
                subviews[index].place(
                    at: CGPoint(
                        x: alignHorizontally(lineWidth, x),
                        y: y + alignVertically(lineHeight, dimension.height)
                    ),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(
                        width: dimension.width,
                        height: dimension.height
                    )
                )
                
                x += dimension.width + horizontalSpacing
                height = max(height, dimension.height)
            }
            y += verticalSpacing + height
        }
    }
    
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
#Preview {
    WrappingHStackLayout(
        alignment: .trailing,
        horizontalSpacing: 8,
        verticalSpacing: 8
    ) {
        Text("Cat 🐱")
            .padding()
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(6)
        Text("Dog 🐶")
            .padding()
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(6)
        Text("Sun 🌞")
            .padding(24)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(6)
        Text("Moon 🌕")
            .padding()
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(6)
        Text("Tree 🌳")
            .padding()
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(6)
    }
    .frame(maxWidth: 200)
}

#endif

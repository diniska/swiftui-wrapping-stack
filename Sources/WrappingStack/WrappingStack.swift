#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 14, macOS 11, *)
public protocol WrappingStack {
    associatedtype Data: RandomAccessCollection
    associatedtype ID: Hashable
    associatedtype Content: View
    
    init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        alignment: Alignment,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat,
        content: @escaping (Data.Element) -> Content
    )
}

@available(iOS 14, macOS 11, *)
public extension WrappingStack {
    
    /// Creates a new WrappingHStackOld
    ///
    /// - Parameters:
    ///   - id: a keypath of element identifier
    ///   - alignment: horizontal and vertical alignment. Vertical alignment is applied to every row
    ///   - horizontalSpacing: horizontal spacing between elements
    ///   - verticalSpacing: vertical spacing between the lines
    ///   - create: a method that creates an array of elements
    init(
        id: KeyPath<Data.Element, ID>,
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat = 0,
        verticalSpacing: CGFloat = 0,
        @ViewBuilder content create: () -> ForEach<Data, ID, Content>
    ) {
        let forEach = create()
        self.init(data: forEach.data,
                  id: id,
                  alignment: alignment,
                  horizontalSpacing: horizontalSpacing,
                  verticalSpacing: verticalSpacing,
                  content: forEach.content)
    }
}

@available(iOS 14, macOS 11, *)
public extension WrappingStack where ID == Data.Element.ID, Data.Element: Identifiable {
    /// Creates a new WrappingStack
    ///
    /// - Parameters:
    ///   - alignment: horizontal and vertical alignment. Vertical alignment is applied to every row
    ///   - horizontalSpacing: horizontal spacing between elements
    ///   - verticalSpacing: vertical spacing between the lines
    ///   - create: a method that creates an array of elements
    init(
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat = 0,
        verticalSpacing: CGFloat = 0,
        @ViewBuilder content create: () -> ForEach<Data, ID, Content>
    ) {
        self.init(id: \.id,
                  alignment: alignment,
                  horizontalSpacing: horizontalSpacing,
                  verticalSpacing: verticalSpacing,
                  content: create)
    }
}


#endif


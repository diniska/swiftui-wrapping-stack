#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 14, macOS 11, *)
public protocol WrappingStack {
    init(
        alignment: Alignment,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat
    )
}

@available(iOS 14, macOS 11, *)
public extension WrappingStack {
    init(
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat = 0,
        verticalSpacing: CGFloat = 0
    ) {
        self.init(alignment: alignment, horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing)
    }
}

#endif

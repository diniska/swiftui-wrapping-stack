#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 13, macOS 10.15, *)
extension View {
    func onSizeChange(perform action: @escaping (CGSize) -> ()) -> some View {
        modifier(SizeReader(onChange: action))
    }
}

@available(iOS 13, macOS 10.15, *)
private struct SizeReader: ViewModifier {
    var onChange: (CGSize) -> ()
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: geometry.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

@available(iOS 13, macOS 10.15, *)
private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

#endif

# SwiftUI WrappingStack

![Swift 5.3](https://img.shields.io/badge/Swift-5.3-FA5B2C) ![Xcode 12.5](https://img.shields.io/badge/Xcode-12-44B3F6) ![iOS 9.0](https://img.shields.io/badge/iOS-8.0-178DF6) ![iPadOS 9.0](https://img.shields.io/badge/iPadOS-8.0-178DF6) ![MacOS 10.10](https://img.shields.io/badge/MacOS-10.10-178DF6) [![Build & Test](https://github.com/diniska/swiftui-wrapping-stack/actions/workflows/test.yml/badge.svg)](https://github.com/diniska/swiftui-wrapping-stack/actions/workflows/test.yml)

A SwiftUI Views for wrapping HStack elements into multiple lines.

## List of supported views

* `WrappingHStack` - provides `HStack` that supports line wrapping

## How to use
### Step 1
Add a dependency using Swift Package Manager to your project: [https://github.com/diniska/swiftui-wrapping-stack](https://github.com/diniska/swiftui-wrapping-stack)

### Step 2
Import the dependency

```swift
import WrappingStack
```

### Step 3
Replace `HStack` with `WrappingHStack` in your view structure. It is compatible with `ForEach`. 
 
```swift
struct MyView: View {

    let elements = ["Cat 🐱", "Dog 🐶", "Sun 🌞", "Moon 🌕", "Tree 🌳"]
    
    var body: some View {
        WrappingHStack(id: \.self) { // use the same id is in the `ForEach` below
            ForEach(elements, id: \.self) { element in
                Text(element)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(6)
            }
        }
        .frame(width: 300) // limiting the width for demo purpose. This line is not needed in real code
    }
    
}
```

The result of the code above:

![WrappingHStack for macOS](./Docs/Resources/wrapping-hstack-macos.png)


## Customization

Customize appearance using the next parameters. All the default SwiftUI modifiers can be applied as well.

### `WrappingHStack` parameters

Parameter name | Description
---------------|--------------
`alignment`    | horizontal and vertical alignment. `.center` is used by default. Vertical alignment is applied to every row
`horizontalSpacing` | horizontal spacing between elements
`verticalSpacing` | vertical spacing between the lines



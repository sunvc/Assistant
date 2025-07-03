//
//  View+.swift
//  Deepseek
//
//  Created by lynn on 2025/7/2.
//
import SwiftUI

extension View {
    
    var screenWidth:CGFloat{
        UIScreen.main.bounds.width
    }
    
    var screenHeight:CGFloat{
        UIScreen.main.bounds.height
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
    }
   @ViewBuilder func customPresentationCornerRadius(_ radius:CGFloat)-> some View{
        if #available(iOS 16.4, *){
            self
                .presentationCornerRadius(radius)
        }else {
            self
        }
    }
    
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    /// https://www.avanderlee.com/swiftui/conditional-view-modifier/
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder func `if` <Content: View>(_ condition: Bool, transform: () -> Content) -> some View {
        if condition {
            transform()
        } else {
            self
        }
    }
    
    @ViewBuilder func diff<Content: View>(transform: (Self) -> Content) -> some View {
        transform(self)
    }
    
    func VButton(_ maxX:Double = 0.0,
                 release:Double = 0.0,
                 onPress: ((DragGesture.Value)->Void)? = nil,
                 onRelease: ((DragGesture.Value)->Bool)? = nil)-> some View{
        modifier(ButtonPress(releaseStyles: release, maxX: maxX, onPress:onPress, onRelease: onRelease))
    }
    
    func customField(icon: String,_ background:Bool = true, complete: (()-> Void)? = nil) -> some View {
        self.modifier(TextFieldModifier( icon: icon,background: background, complete: complete))
    }
    
}

// MARK: - buttons 视图
struct ButtonPress: ViewModifier{
    var releaseStyles:Double = 0.0
    var maxX:Double = 0.0
    var onPress:((DragGesture.Value)->Void)? = nil
    var onRelease:((DragGesture.Value)->Bool)? = nil
    
    @State private var ispress = false
    
   public func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .scaleEffect(ispress ? 0.99 : 1)
            .opacity(ispress ? 0.6 : 1)
            .animation(.easeInOut(duration: 0.1), value: ispress)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ result in
                        self.ispress = true
                        onPress?(result)
                        if releaseStyles > 0.0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + releaseStyles ){
                                self.ispress = false
                            }
                        }
                    })
                    .onEnded({ result in
                        self.ispress = false
                        if abs(result.translation.width) <= maxX {
                            
                            if let success = onRelease?(result), success{
                                Haptic.impact()
                            }
                        }
                    })
            )
    }
}


// MARK: - TextFieldModifier
struct TextFieldModifier: ViewModifier {
    var icon: String
    var background: Bool = true
    var complete: (()-> Void)? = nil
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                HStack {
                    Image(systemName: icon)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .modifier(OutlineOverlay(cornerRadius: 14))
                        .offset(x: -46)
                        .accessibility(hidden: true)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.tint, .secondary)
                        .onTapGesture {
                            complete?()
                            Haptic.impact()
                        }
                    Spacer()
                }
            )
            .padding()
            .padding(.leading, 43)
            .if(background){ view in
                view
                    .background(.ultraThinMaterial)
            }
            .cornerRadius(20)
            .modifier(OutlineOverlay(cornerRadius: 20))
    }
}


// MARK: - BackgroundStyle 视图
struct OutlineOverlay: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 20
    
    public func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    .linearGradient(
                        colors: [
                            .white.opacity(colorScheme == .dark ? 0.6 : 0.3),
                            .black.opacity(colorScheme == .dark ? 0.3 : 0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom)
                )
                .blendMode(.overlay)
        )
    }
}

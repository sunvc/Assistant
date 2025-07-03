
import MarkdownUI
import SwiftUI
import Splash


public struct CodeBlock: View {
    var configuration: CodeBlockConfiguration
    
    public init(_ configuration: CodeBlockConfiguration) {
        self.configuration = configuration
    }
    
    public var language: String {
        configuration.language ?? "code"
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(language)
                    .font(.footnote)
                    .fontWeight(.semibold)
                Spacer()
                
                Button(action: {
                    Clipboard.set(configuration.content)
                }) {
                    Image(systemName: "doc.on.doc")
                        .padding(7)
                }
                .buttonStyle(GrowingButton())
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(MarkdownColors.secondaryBackground)
            
            Divider()
            
            ScrollView(.horizontal) {
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.225))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding(16)
            }
        }
        .background(MarkdownColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .markdownMargin(top: .zero, bottom: .em(0.8))
    }
}

public struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>
    
    public init(theme: Splash.Theme) {
        self.syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: theme))
    }
    
    public func highlightCode(_ content: String, language: String?) -> Text {
        guard language != nil else {
            return Text(content)
        }
        
        return self.syntaxHighlighter.highlight(content)
    }
}

public extension CodeSyntaxHighlighter where Self == SplashCodeSyntaxHighlighter {
    static func splash(theme: Splash.Theme) -> Self {
        SplashCodeSyntaxHighlighter(theme: theme)
    }
}

public struct TextOutputFormat: OutputFormat {
    private let theme: Splash.Theme
    
    public init(theme: Splash.Theme) {
        self.theme = theme
    }
    
    public func makeBuilder() -> Builder {
        Builder(theme: self.theme)
    }
}

public extension TextOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: Splash.Theme
        private var accumulatedText: [Text]
        
        fileprivate init(theme: Splash.Theme) {
            self.theme = theme
            self.accumulatedText = []
        }
        
        public mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = self.theme.tokenColors[type] ?? self.theme.plainTextColor
            self.accumulatedText.append(Text(token).foregroundColor(.init(color)))
        }
        
        public mutating func addPlainText(_ text: String) {
            self.accumulatedText.append(
                Text(text).foregroundColor(.init(self.theme.plainTextColor))
            )
        }
        
        public mutating func addWhitespace(_ whitespace: String) {
            self.accumulatedText.append(Text(whitespace))
        }
        
        public func build() -> Text {
            self.accumulatedText.reduce(Text(verbatim: ""), +)
        }
    }
}

public struct GrowingButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}



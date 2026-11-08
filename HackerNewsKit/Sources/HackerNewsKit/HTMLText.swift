import Foundation

/// Converts the small subset of HTML that Hacker News uses for comments and posts
/// (`<p>`, `<i>`, `<b>`, `<a>`, `<pre>`, `<code>` and entities) into an `AttributedString`.
///
/// Links keep their destination, so SwiftUI's `Text` makes them tappable.
public enum HTMLText {

    public static func attributedString(from html: String) -> AttributedString {
        var result = AttributedString()
        var emphasis = 0
        var strong = 0
        var code = 0
        var preformatted = 0
        var link: URL?

        func append(_ text: String) {
            guard !text.isEmpty else { return }
            var run = AttributedString(text)
            var intent: InlinePresentationIntent = []
            if emphasis > 0 { intent.insert(.emphasized) }
            if strong > 0 { intent.insert(.stronglyEmphasized) }
            if code > 0 { intent.insert(.code) }
            if !intent.isEmpty { run.inlinePresentationIntent = intent }
            run.link = link
            result += run
        }

        func appendParagraphBreak() {
            guard !result.characters.isEmpty, !result.characters.reversed().starts(with: "\n\n") else { return }
            result += AttributedString(result.characters.last == "\n" ? "\n" : "\n\n")
        }

        var remaining = html[...]
        while !remaining.isEmpty {
            guard let tagStart = remaining.firstIndex(of: "<") else {
                append(decodeEntities(remaining, collapsingWhitespace: preformatted == 0))
                break
            }
            append(decodeEntities(remaining[..<tagStart], collapsingWhitespace: preformatted == 0))

            guard let tagEnd = remaining[tagStart...].firstIndex(of: ">") else {
                append(decodeEntities(remaining[tagStart...], collapsingWhitespace: preformatted == 0))
                break
            }
            let tag = Tag(remaining[remaining.index(after: tagStart)..<tagEnd])
            remaining = remaining[remaining.index(after: tagEnd)...]

            switch (tag.name, tag.isClosing) {
            case ("p", false), ("br", _):
                appendParagraphBreak()
            case ("pre", false):
                appendParagraphBreak()
                preformatted += 1
            case ("pre", true):
                preformatted = max(0, preformatted - 1)
                appendParagraphBreak()
            case ("i", false), ("em", false): emphasis += 1
            case ("i", true), ("em", true): emphasis = max(0, emphasis - 1)
            case ("b", false), ("strong", false): strong += 1
            case ("b", true), ("strong", true): strong = max(0, strong - 1)
            case ("code", false): code += 1
            case ("code", true): code = max(0, code - 1)
            case ("a", false): link = tag.attribute("href").flatMap { URL(string: decodeEntities($0[...], collapsingWhitespace: false)) }
            case ("a", true): link = nil
            default: break
            }
        }

        return result.trimmingNewlines()
    }

    static func decodeEntities(_ text: Substring, collapsingWhitespace: Bool) -> String {
        var output = ""
        output.reserveCapacity(text.utf8.count)
        var remaining = text
        while let ampersand = remaining.firstIndex(of: "&") {
            output += remaining[..<ampersand]
            let afterAmpersand = remaining.index(after: ampersand)
            if let semicolon = remaining[afterAmpersand...].prefix(10).firstIndex(of: ";"),
               let decoded = decodeEntity(remaining[afterAmpersand..<semicolon]) {
                output.append(decoded)
                remaining = remaining[remaining.index(after: semicolon)...]
            } else {
                output.append("&")
                remaining = remaining[afterAmpersand...]
            }
        }
        output += remaining

        guard collapsingWhitespace else { return output }
        return output.replacing(/\s+/, with: " ")
    }

    private static func decodeEntity(_ name: Substring) -> Character? {
        switch name {
        case "amp": return "&"
        case "lt": return "<"
        case "gt": return ">"
        case "quot": return "\""
        case "apos": return "'"
        case "nbsp": return "\u{00A0}"
        default: break
        }
        guard name.first == "#" else { return nil }
        let number = name.dropFirst()
        let value = number.first == "x" || number.first == "X"
            ? UInt32(number.dropFirst(), radix: 16)
            : UInt32(number)
        return value.flatMap(Unicode.Scalar.init).map(Character.init)
    }
}

private struct Tag {
    let name: String
    let isClosing: Bool
    private let source: Substring

    init(_ source: Substring) {
        self.source = source
        isClosing = source.first == "/"
        name = source
            .drop { $0 == "/" }
            .prefix { !$0.isWhitespace && $0 != "/" }
            .lowercased()
    }

    func attribute(_ attribute: String) -> String? {
        source.matches(of: /\s(\w+)\s*=\s*"([^"]*)"/)
            .first { $0.output.1.lowercased() == attribute }
            .map { String($0.output.2) }
    }
}

private extension AttributedString {
    func trimmingNewlines() -> AttributedString {
        let characters = self.characters
        guard let first = characters.firstIndex(where: { !$0.isNewline }),
              let last = characters.lastIndex(where: { !$0.isNewline }) else {
            return AttributedString()
        }
        return AttributedString(self[first...last])
    }
}

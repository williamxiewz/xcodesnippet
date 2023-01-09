//
//  FrontMatter.swift
//  xcodesnippet
//
//  Created by Watanabe Toshinori on 2022/05/06.
//

import Foundation
import Yams

struct FrontMatter: CodeSnippetConvertible, CodeSnippetExportable {
    let yaml: String

    let content: String

    init(string: String) throws {
        let regex = try! NSRegularExpression(pattern: #"\A---\n\n?([\s\S]*)---\n\n?([\s\S]*)"#)
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        guard let match = matches.first,
            match.numberOfRanges == 3,
            let yamlRange = Range(match.range(at: 1), in: string),
            let contentRange = Range(match.range(at: 2), in: string)
        else {
            throw CodeSnippetError.frontMatterNotDetected
        }

        yaml = String(string[yamlRange])
        content = String(string[contentRange])
    }

    // MARK: - CodeSnippetConvertible

    static func canCreate(with url: URL) -> Bool {
        ["swift", "mm", "m"].contains(url.pathExtension)
    }

    static func createCodeSnippet(url: URL) throws -> CodeSnippet {
        guard let string = try? String(contentsOf: url), !string.isEmpty else {
            throw CodeSnippetError.fileIsEmpty
        }
        let frontMatter = try FrontMatter(string: string)

        let fileName = url.lastPathComponent
        let variables = try? Yams.load(yaml: frontMatter.yaml) as? [String: Any]

        let completion = (fileName as NSString).deletingPathExtension
        let language: String = {
            switch (fileName as NSString).pathExtension {
            case "swift": return "Xcode.SourceCodeLanguage.Swift"
            case "m": return "Xcode.SourceCodeLanguage.Objective-C"
            case "mm": return "Xcode.SourceCodeLanguage.Objective-C++"
            default: return ""
            }
        }()
        let completionScopes: [String] = {
            let allowedScopes = ["All", "CodeExpression", "ClassImplementation", "TopLevel", "StringOrComment", "CodeBlock"]
            if let completionScope = variables?["completion-scope"] as? String {
                if allowedScopes.contains(completionScope) {
                    return [completionScope]
                }
            } else if let completionScopes = variables?["completion-scopes"] as? [String] {
                let filteredCompletionScopes = completionScopes.filter { allowedScopes.contains($0) }
                if !filteredCompletionScopes.isEmpty {
                    return filteredCompletionScopes
                }
            }
            return ["All"]
        }()
        let identifier = UUID().uuidString

        return CodeSnippet(contents: frontMatter.content,
                           completionPrefix: completion,
                           language: language,
                           title: variables?["title"] as? String ?? "",
                           summary: variables?["summary"] as? String ?? "",
                           completionScopes: completionScopes,
                           identifier: identifier,
                           isUserSnippet: true,
                           version: 0)
    }

    // MARK: - CodeSnippetExportable

    static var exportTypeName: String { "frontmatter" }

    static func export(codeSnippet: CodeSnippet, at url: URL) throws {
        let pathExtension: String = {
            switch codeSnippet.language {
            case "Xcode.SourceCodeLanguage.Swift":return "swift"
            case "Xcode.SourceCodeLanguage.Objective-C": return "m"
            case "Xcode.SourceCodeLanguage.Objective-C++": return "mm"
            default: return ""
            }
        }()
        let outputPath = url.appendingPathComponent(codeSnippet.completionPrefix + "." + pathExtension)

        let frontMatterString = string(from: codeSnippet)
        let data = frontMatterString.data(using: .utf8) ?? Data()
        try data.write(to: outputPath)
    }

    // MARK: - String representation

    static func string(from codeSnippet: CodeSnippet) -> String {
        var variants = [String]()

        if !codeSnippet.title.isEmpty {
            variants.append("title: \(codeSnippet.title)")
        }

        if !codeSnippet.summary.isEmpty {
            variants.append("summary: \(codeSnippet.summary)")
        }

        let completionScopes: String = {
            switch codeSnippet.completionScopes.count {
            case 0: return ""
            case 1: return "completion-scope: \(codeSnippet.completionScopes[0])"
            default: return "completion-scopes:\n" + codeSnippet.completionScopes.map { "  - \($0)" }.joined(separator: "\n")
            }
        }()
        variants.append(completionScopes)

        return """
               ---
               \(variants.joined(separator: "\n"))
               ---

               \(codeSnippet.contents)
               """
    }
}

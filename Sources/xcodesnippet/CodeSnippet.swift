//
//  CodeSnippet.swift
//  xcodesnippet
//
//  Created by Watanabe Toshinori on 2022/05/06.
//

import Foundation

struct CodeSnippet: Codable, CodeSnippetConvertible, CodeSnippetExportable {
    let contents: String

    let completionPrefix: String

    let language: String

    let title: String

    let summary: String

    let completionScopes: [String]

    let identifier: String

    let isUserSnippet: Bool

    let version: Int

    var fileName: String {
        identifier + ".codesnippet"
    }

    var friendlyFileName: String {
        completionPrefix + ".codesnippet"
    }

    enum CodingKeys: String, CodingKey {
        case contents = "IDECodeSnippetContents"
        case completionPrefix = "IDECodeSnippetCompletionPrefix"
        case language = "IDECodeSnippetLanguage"
        case title = "IDECodeSnippetTitle"
        case summary = "IDECodeSnippetSummary"
        case completionScopes = "IDECodeSnippetCompletionScopes"
        case identifier = "IDECodeSnippetIdentifier"
        case isUserSnippet = "IDECodeSnippetUserSnippet"
        case version = "IDECodeSnippetVersion"
    }

    // MARK: - CodeSnippetConvertible

    static func canCreate(with url: URL) -> Bool {
        url.pathExtension == "codesnippet"
    }

    static func createCodeSnippet(url: URL) throws -> CodeSnippet {
        guard let data = try? Data(contentsOf: url), !data.isEmpty else {
            throw CodeSnippetError.fileIsEmpty
        }
        return try PropertyListDecoder().decode(CodeSnippet.self, from: data)
    }

    // MARK: - CodeSnippetExportable

    static var exportTypeName: String { "codesnippet" }

    static func export(codeSnippet: CodeSnippet, at url: URL) throws {
        let outputPath = url.appendingPathComponent(codeSnippet.friendlyFileName)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(codeSnippet)
        try data.write(to: outputPath)
    }

    // MARK: - String representation

    var prettyPrint: String {
        var variants = [String]()

        variants.append("title: \(title)")

        variants.append("summary: \(summary)")

        let outputLanguage: String = {
            switch language {
            case "Xcode.SourceCodeLanguage.Swift":return "Swift"
            case "Xcode.SourceCodeLanguage.Objective-C": return "Objective-C"
            case "Xcode.SourceCodeLanguage.Objective-C++": return "Objective-C++"
            default: return ""
            }
        }()
        variants.append("Language: \(outputLanguage)")
        variants.append("Completion: \(completionPrefix)")

        let availability: String = {
            switch completionScopes.count {
            case 0: return "Availability: All"
            case 1: return "Availability: \(completionScopes[0])"
            default: return "Availability:\n" + completionScopes.map { "  - \($0)" }.joined(separator: "\n")
            }
        }()
        variants.append(availability)

        return """
               ---
               \(variants.joined(separator: "\n"))
               ---

               \(contents)
               """
    }
}

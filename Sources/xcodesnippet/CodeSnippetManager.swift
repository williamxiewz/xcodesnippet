//
//  CodeSnippetManager.swift
//  xcodesnippet
//
//  Created by Watanabe Toshinori on 2022/05/06.
//

import Foundation

class CodeSnippetManager: NSObject {
    // MARK: - Directories

    let codeSnippetsDirectory: URL = {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("/Library/Developer/Xcode/UserData/CodeSnippets/")
    }()

    // MARK: - Supported Formats

    private let supportedInputFormats: [CodeSnippetConvertible.Type] = [
        CodeSnippet.self,
        FrontMatter.self,
    ]

    private let supporteeExportFormats: [CodeSnippetExportable.Type] = [
        CodeSnippet.self,
        FrontMatter.self,
    ]

    // MARK: - Creating a CodeSnippetManager

    static let `default` = CodeSnippetManager()

    override private init() {
        // Creating snippets directory if needed
        if !FileManager.default.fileExists(atPath: codeSnippetsDirectory.path) {
            try? FileManager.default.createDirectory(atPath: codeSnippetsDirectory.path, withIntermediateDirectories: true, attributes: nil)
        }
    }

    // MARK: - Loading Code Snippets

    func codeSnippet(at url: URL) throws -> CodeSnippet {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CodeSnippetError.fileNotExists
        }

        guard let codeSnippet = try supportedInputFormats
                .first(where: { $0.canCreate(with: url) })?
                .createCodeSnippet(url: url)
        else {
            throw CodeSnippetError.fileFormatNotSupported
        }

        return codeSnippet
    }

    func codeSnippetsOfDirectory(at url: URL, inculdeSubDirectories: Bool = false) throws -> [CodeSnippet] {
        if inculdeSubDirectories {
            print(url.path)
            return FileManager.default
                .enumerator(at: url, includingPropertiesForKeys: nil)?
                .compactMap { $0 as? URL }
                .compactMap({ v in
                    print(v)
                    return v
                })
                .compactMap { url in
                    try? codeSnippet(at: url)
                } ?? []

        } else {
            return try FileManager.default
                .contentsOfDirectory(atPath: url.path)
                .compactMap { fileName in
                    try? codeSnippet(at: url.appendingPathComponent(fileName))
                }
        }
    }

    // MARK: - Saving and Deleting Code Snippets

    func save(_ codeSnippet: CodeSnippet, force: Bool = false) throws -> URL {
        let savedCodeSnippets = try? codeSnippetsOfDirectory(at: codeSnippetsDirectory)
        if let duplicatedCodeSnippet = savedCodeSnippets?
            .first(where: { $0.completionPrefix == codeSnippet.completionPrefix }) {
            if !force, duplicatedCodeSnippet.version >= duplicatedCodeSnippet.version {
                throw CodeSnippetError.duplicated
            }
            try remove(duplicatedCodeSnippet)
        }

        let outputPath = codeSnippetsDirectory.appendingPathComponent(codeSnippet.fileName)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(codeSnippet)
        try data.write(to: outputPath)
        return outputPath
    }

    func remove(_ codeSnippet: CodeSnippet) throws {
        let url = codeSnippetsDirectory.appendingPathComponent(codeSnippet.fileName)
        let friendlyURL = codeSnippetsDirectory.appendingPathComponent(codeSnippet.fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(atPath: url.path)
        } else if FileManager.default.fileExists(atPath: friendlyURL.path) {
            try FileManager.default.removeItem(atPath: friendlyURL.path)
        }
    }

    // MARK: - Exporting Code Snippets

    func supportedExportFormats() -> [String] {
        supporteeExportFormats.map { $0.exportTypeName }
    }

    func export(_ codeSnippet: CodeSnippet, at url: URL, exportFormat: String) throws {
        try supporteeExportFormats
            .first(where: { $0.exportTypeName == exportFormat.lowercased() })?
            .export(codeSnippet: codeSnippet, at: url)
    }
}

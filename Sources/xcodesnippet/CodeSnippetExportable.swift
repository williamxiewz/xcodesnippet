//
//  CodeSnippetExportable.swift
//  xcodesnippet
//
//  Created by Watanabe Toshinori on 2022/05/06.
//

import Foundation

protocol CodeSnippetExportable {
    static var exportTypeName: String { get }

    static func export(codeSnippet: CodeSnippet, at url: URL) throws
}

//
//  CodeSnippetConvertible.swift
//  xcodesnippet
//
//  Created by Watanabe Toshinori on 2022/05/06.
//

import Foundation

protocol CodeSnippetConvertible {
    static func canCreate(with url: URL) -> Bool

    static func createCodeSnippet(url: URL) throws -> CodeSnippet
}

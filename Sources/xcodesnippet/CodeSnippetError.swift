//
//  CodeSnippetError.swift
//  xcodesnippet
//
//  Created by Watanabe Toshinori on 2022/05/06.
//

import Foundation

enum CodeSnippetError: Error, LocalizedError {
    case fileFormatNotSupported

    case fileNotExists

    case fileIsEmpty

    case duplicated

    case frontMatterNotDetected

    var errorDescription: String? {
        switch self {
        case .fileFormatNotSupported: return "File format of the specified file is not supported."
        case .fileNotExists: return "The specified file does not exist."
        case .fileIsEmpty: return "The specified file is empty."
        case .duplicated: return "Duplicate code snippet already installed."
        case .frontMatterNotDetected: return "FrontMatter not found in the specified file."
        }
    }
}

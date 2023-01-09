//
//  commands.swift
//  xcodesnippet
//
//  Created by Watanabe Toshinori on 2022/05/06.
//

import Foundation
import ArgumentParser

@main
struct Xcodesnippet: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A command line utility for managing Code Snippets of XCode.",
        version: "0.0.1",
        subcommands: [Install.self, RemoteInstall.self, Show.self, Remove.self, List.self, Open.self, Export.self],
        defaultSubcommand: Install.self
    )
}

extension Xcodesnippet {
    struct Install: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Install code snippet"
        )

        @Flag(name: .shortAndLong, help: "Overwrite duplicate code snippet.")
        var force = false

        @Argument(help: "Specify the code snippet file.")
        var file: String

        mutating func run() {
            do {
                var isDirectory: ObjCBool = false
                if !FileManager.default.fileExists(atPath: file, isDirectory: &isDirectory) {
                    throw CodeSnippetError.fileNotExists
                }

                let url = URL(fileURLWithPath: file)
                if isDirectory.boolValue {
                    let codeSnippets = try CodeSnippetManager.default.codeSnippetsOfDirectory(at: url)
                    codeSnippets.forEach { codeSnippet in
                        do {
                            let outputPath = try CodeSnippetManager.default.save(codeSnippet, force: force)
                            print("Installed code snippet")
                            print(outputPath)
                        } catch {
                            print("Error: " + error.localizedDescription)
                        }
                    }
                } else {
                    let codeSnippet = try CodeSnippetManager.default.codeSnippet(at: url)
                    let outputPath = try CodeSnippetManager.default.save(codeSnippet, force: force)
                    print("Installed code snippet")
                    print(outputPath)
                }
            } catch {
                print("Error: " + error.localizedDescription)
            }
        }
    }

    struct RemoteInstall: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Install code snippet from remote repository"
        )

        @Flag(name: .shortAndLong, help: "Overwrite duplicate code snippet.")
        var force = false

        @Argument(help: "Specify the URL of the remote repository.")
        var url: String

        mutating func run() {
            do {
                let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil)

                defer {
                    try? FileManager.default.removeItem(atPath: temporaryDirectory.path)
                }

                // Clone git repository
                let process = Process()
                process.launchPath = "/usr/bin/env"
                process.arguments = ["git", "clone", url, temporaryDirectory.path]
                process.launch()
                process.waitUntilExit()

                guard process.terminationStatus == 0 else {
                    print("Error: Failed to clone the remote repository.")
                    return
                }

                let codeSnippets = try CodeSnippetManager.default.codeSnippetsOfDirectory(at: temporaryDirectory, inculdeSubDirectories: true)
                guard !codeSnippets.isEmpty else {
                    print("Error: No code snippet found in the remote repository.")
                    return
                }
                codeSnippets.forEach { codeSnippet in
                    do {
                        let outputPath = try CodeSnippetManager.default.save(codeSnippet, force: force)
                        print("Installed code snippet")
                        print(outputPath)
                    } catch {
                        print("Error: " + error.localizedDescription)
                    }
                }
            } catch {
                print("Error: " + error.localizedDescription)
            }
        }
    }

    struct Remove: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Remove code snippet"
        )

        @Argument(help: "Specify the code snippet completion.")
        var completion: String = ""

        @Flag(name: .shortAndLong, help: "Remove all installed code snippets.")
        var all = false

        mutating func run() {
            do {
                let codeSnippets = try CodeSnippetManager.default.codeSnippetsOfDirectory(at: CodeSnippetManager.default.codeSnippetsDirectory)
                if all {
                    codeSnippets.forEach { codeSnippet in
                        do {
                            try CodeSnippetManager.default.remove(codeSnippet)
                        } catch {
                            print("Error: " + error.localizedDescription)
                        }
                    }
                    print("Removed code snippet")
                } else {
                    guard let codeSnippet = codeSnippets.first(where: { $0.completionPrefix == completion }) else {
                        print("Error: The code snippet for the given completion not found.")
                        return
                    }

                    try CodeSnippetManager.default.remove(codeSnippet)
                    print("Removed code snippet")
                }
            } catch {
                print("Error: " + error.localizedDescription)
            }
        }
    }

    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "List installed code snippets"
        )

        mutating func run() {
            do {
                let codeSnippets = try CodeSnippetManager.default.codeSnippetsOfDirectory(at: CodeSnippetManager.default.codeSnippetsDirectory)
                print(codeSnippets.map({ $0.completionPrefix }).joined(separator: "\n"))
            } catch {
                print("Error: " + error.localizedDescription)
            }
        }
    }

    struct Show: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Shows a detail of code snippet"
        )

        @Argument(help: "Specify the code snippet completion.")
        var completion: String

        mutating func run() {
            do {
                let codeSnippets = try CodeSnippetManager.default.codeSnippetsOfDirectory(at: CodeSnippetManager.default.codeSnippetsDirectory)
                guard let codeSnippet = codeSnippets.first(where: { $0.completionPrefix == completion }) else {
                    print("Error: The code snippet for the given completion not found.")
                    return
                }
                print(codeSnippet.prettyPrint)
            } catch {
                print("Error: " + error.localizedDescription)
            }
        }
    }

    struct Open: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Open code snippets location"
        )

        mutating func run() {
            let process = Process()
            process.launchPath = "/usr/bin/open"
            process.arguments = [CodeSnippetManager.default.codeSnippetsDirectory.path]
            process.launch()
        }
    }

    struct Export: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Export code snippets"
        )

        @Argument(help: "Specify the output directory.")
        var output: String = "."

        @Option(name: .shortAndLong, help: "Specify the export file format (\(CodeSnippetManager.default.supportedExportFormats().joined(separator: ", "))).")
        var format: String = FrontMatter.exportTypeName

        mutating func run() {
            do {
                let codeSnippets = try CodeSnippetManager.default.codeSnippetsOfDirectory(at: CodeSnippetManager.default.codeSnippetsDirectory)
                guard !codeSnippets.isEmpty else {
                    print("Error: No code snippet installed.")
                    return
                }

                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: output, isDirectory: &isDirectory), !isDirectory.boolValue {
                    print("Error: The specified output path is not a directory.")
                    return
                }

                let supportedFormat = CodeSnippetManager.default.supportedExportFormats()
                guard supportedFormat.contains(format.lowercased()) else {
                    print("Error: The specified output format is not supported.")
                    return
                }

                let url = URL(fileURLWithPath: output)
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)

                codeSnippets.forEach { codeSnippet in
                    do {
                        try CodeSnippetManager.default.export(codeSnippet, at: url, exportFormat: format)
                    } catch {
                        print("Error: " + error.localizedDescription)
                    }
                }

                print("Exported code snippets")
            } catch {
                print("Error: " + error.localizedDescription)
            }
        }
    }
}

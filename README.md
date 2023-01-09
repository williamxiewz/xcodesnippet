# xcodesnippet

`xcodesnippet` is a command line utility for managing Code Snippets of Xcode.\
Various tasks related to code snippets can be performed from the command line.

```console
$ xcodesnippet install print_hello_world.swift
Installed code snippet

$ xcodesnippet list
print_hello_world

$ xcodesnippet export MyCodeSnippets
Exported code snippet
```

This tool was developed with great inspiration from Matt Thompson's [Xcode-Snippets](https://github.com/Xcode-Snippets/xcodesnippet) script.


- [Installation](#installation)
    - [Requirements](#requirements)
    - [Build](#build)
- [Usage](#usage)
    - [Commands](#commands)
    - [Supported Formats](#supported-formats)
- [Author](#author)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Installation

### Requirements

* Xcode 13.2+
* Swift 5.4+

### Build

Clone this repository and build from the terminal.

```console
$ cd path/to/xcodesnippet
$ swift build
```

Use `swift run` to execute the command.

```console
$ swift run xcodesnippet install --help
```

Use the `release` option to create a universal binary.

```console
$ swift build -c release --arch arm64 --arch x86_64
```

**Note:** If you encounter the following error during build, please check your xcode version. v13.2 or higher is required.

```console
error: concurrency is only available in macOS 12.0.0 or newer
```

## Usage

Execute the following command from the terminal.

```console
$ xcodesnippet <Commands> <Options>
```

Use `xcodesnippet -help` or `xcodesnippet <Commands> -help` to see options.

### Commands

#### install

```console
$ xcodesnippet install <file or directory>
```

Install the specified file as Code Snippets in Xcode.
If a directory is specified, all code snippets under the specified directory will be installed.\
If there is a duplicate code snippet already installed, the installation will be canceled. If you wish to disable this behavior, specify the `--force` option.

#### remote-install

```console
$ xcodesnippet remote-install <URL of git repository>
```

Get the code snippets from the git repository and install them as Code Snippets in Xcode.
All code snippets in the specified repository will be installed. Sub-directories as well as the root directory will be searched.

#### remove

```console
$ xcodesnippet remove <completion of codesnippet>
```

Removes installed code snippets with the specified `completion`. 
The `-all` option removes ALL installed code snippets

#### list

```console
$ xcodesnippet list
```

Lists all installed code snippets.

#### show

```console
$ xcodesnippet show <completion of codesnippet>
```

Displays details of installed code snippets with the specified `completion`.

#### open

```console
$ xcodesnippet open
```

Open Xcode's Code Snippets directory.

#### export

```console
$ xcodesnippet export <output directory>
```

Exports installed code snippets to the specified directory.
The `-format` option allows you to specify the file format for export. 

### Supported Formats

Code snippet installation and export supports the following formats.

#### Front Matter

The tool uses Front Matter as its default format because of its high readability and ease of writing code snippets.

[Front matter](https://jekyllrb.com/docs/front-matter/) has a YAML block surrounded by three dashes in the header of file.
The YAML supported by this tool is in the same format as used in [Xcode-Snippets](https://github.com/Xcode-Snippets/xcodesnippet). It contains three elements: `title`, `summary` and `completion-scope`.

```yaml
---
title: "Hello, World!"
summary: "Prints 'Hello World'"
completion-scope: CodeBlock
---

print("Hello, World!")
```

The file name is used as the `completion` of code snippets. The file extension can be `swift`, `m` or `mm`.

#### Code Snippet

Code Snippet is a plist format file used as a code snippet in Xcode.
There is no detailed documentation on this file format and readability is not so good, but you can find many repositories on github where files in this format are stored.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>IDECodeSnippetCompletionPrefix</key>
	<string>print_hello_world</string>
	<key>IDECodeSnippetCompletionScopes</key>
	<array>
		<string>CodeBlock</string>
	</array>
	<key>IDECodeSnippetContents</key>
	<string>println("Hello, World!")</string>
	<key>IDECodeSnippetSummary</key>
	<string>Prints `Hello, World`</string>
	<key>IDECodeSnippetTitle</key>
	<string>Hello, World!</string>
    ...
```

## Author

Watanabe Toshinori – toshinori_watanabe@tiny.blue

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

This application makes use of the following third party libraries:

*  [Yams](https://github.com/jpsim/Yams) - YAML Parser

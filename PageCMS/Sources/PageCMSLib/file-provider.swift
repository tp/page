//
//  file-provider.swift
//  page-cmsPackageDescription
//
//  Created by Timm Preetz on 11.01.18.
//

import Foundation
import SwiftMarkdown
import Stencil
import FileKit

let cwd = FileManager.default.currentDirectoryPath

// TODO: Create redirects from Symlinks ?

public struct ArticleMapping {
    public init(sourceDirectoryPath: Path, outputDirectoryPrefix: Path) {
        self.sourceDirectoryPath = sourceDirectoryPath
        self.outputDirectoryPrefix = outputDirectoryPrefix
    }
    
    let sourceDirectoryPath: Path
    let outputDirectoryPrefix: Path
}

public struct PageMapping {
    public init(sourceDirectoryPath: Path, outputDirectoryPrefix: Path) {
        self.sourceDirectoryPath = sourceDirectoryPath
        self.outputDirectoryPrefix = outputDirectoryPrefix
    }
    
    let sourceDirectoryPath: Path
    let outputDirectoryPrefix: Path
}


public struct StaticFileMapping {
    public init(inputPath: Path, outPath: Path) {
        self.inputPath = inputPath
        self.outPath = outPath
    }
    
    let inputPath: Path
    let outPath: Path
}

public struct SiteConfiguration {
    public init(rootOutputDirectory: Path, siteContext: [String: Any], articleMappings: [ArticleMapping], pageMappings: [PageMapping], staticFileMappings: [StaticFileMapping]) {
        self.rootOutputDirectory = rootOutputDirectory
        self.siteContext = siteContext
        self.articleMappings = articleMappings
        self.pageMappings = pageMappings
        self.staticFileMappings = staticFileMappings
    }
    
    public let rootOutputDirectory: Path;
    public let siteContext: [String: Any]
    public let articleMappings: [ArticleMapping]
    public let pageMappings: [PageMapping]
    public let staticFileMappings: [StaticFileMapping]
}

public func generateSite(_ configuration: SiteConfiguration) throws {
    struct Article {
        let title: String
        let date: String
        let url: String
        let bodyHTML: String
    }
    
    let environment = Environment()
    
    func renderBody(source: WebPageSource, context: [String: Any] = [:]) throws -> String {
        //    var pageHTML: String = ""
        if (source.type == PageType.markdown) {
            let markdownSource = try String(contentsOf: source.fullSourcePath.url, encoding: .utf8)
            return try markdownToHTML(convertFootnotes(input: markdownSource), options: [])
        } else {
            // plain or HTML
            
            let fileContents = try String(contentsOf: source.fullSourcePath.url, encoding: .utf8)
            
            let context: [String: Any] = [
                "site": configuration.siteContext,
                ].merging(context, uniquingKeysWith: { (first, _) in first });
            
            return try environment.renderTemplate(string: fileContents, context: context)
        }
    }
    
    
    for articleMapping in configuration.articleMappings {
        try (configuration.rootOutputDirectory + articleMapping.outputDirectoryPrefix).createDirectory()
    }
    
    for staticFileMapping in configuration.staticFileMappings {
        try staticFileMapping.inputPath.copyFile(to: configuration.rootOutputDirectory + staticFileMapping.outPath)
    }
    
    let articles = try configuration.articleMappings.flatMap({ mapping in
        return try readPageSources(directory: mapping.sourceDirectoryPath, outputPrefixFolder: mapping.outputDirectoryPrefix) // TODO: New "Post" struct, ability to overwrite URLs from within the file? (In order to support/enforce legacy URLs?) Or maybe just have multiple sources, and then merge them into a common `posts`
    })

    let mainPages = try configuration.pageMappings.flatMap({ mapping in
        return try readPageSources(directory: mapping.sourceDirectoryPath, outputPrefixFolder: mapping.outputDirectoryPrefix)
    })
    
    
    let template = try String(contentsOf: Path("\(cwd)/../_layouts/default.html").url, encoding: .utf8) // TODO: make configurable / dynamic based on page/post
    
    let posts: [Article] = try articles.map {
        x -> Article in
        let url = (Path("/") + x.relativeOutputPath).resolved.rawValue.replacingOccurrences(of: "./", with: "/").replacingOccurrences(of: ".html", with: "").replacingOccurrences(of: "/index", with: "/")
        print("url", url, x.fullSourcePath)
        let date = nameFromFilePath(x.fullSourcePath.rawValue) ?? "1970-01-01"
        let title = titleFromPostMarkdown(x.fullSourcePath) ?? "No title"
        let body = try renderBody(source: x)
        
        return Article(title: title, date: date, url: url, bodyHTML: body)
    }.sorted {
            a, b in
            return a.date > b.date;
    }
    
    let recentPosts: [Article] = Array(posts.prefix(5))
    
    struct RssItem {
        let title: String
        let excerpt: String
        let rssDate: String
        let isoDate: String
        let url: String
        let id: String
    }
    
    let rssFeedItems: [RssItem] = recentPosts.map {
        post in
        
        //    let escapedTitle: String = {
        //        return CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, post.title as CFString, "[]." as CFString,":/?&=;+!@#$()',*" as CFString,CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue))
        //        }() as String!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: post.date) else {
            fatalError("ERROR: Date conversion failed due to mismatched format.")
        }
        let postDate = date.addingTimeInterval(TimeInterval(60 * 60 * 12));
        
        let rfcDateFormat = DateFormatter()
        rfcDateFormat.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        let rssDate = rfcDateFormat.string(from: postDate)
        
        let iso8601Formatter = DateFormatter(); // ISO8601DateFormatter() does not work with SPM
        iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        let isoDate = iso8601Formatter.string(from: postDate)
        
        return RssItem(title: post.title, excerpt: post.bodyHTML, rssDate: rssDate, isoDate: isoDate, url: post.url, id: post.url)
    }
    
    for page in (articles + mainPages) {
        let outputFilePath = configuration.rootOutputDirectory + page.relativeOutputPath
        print("outputFilePath", outputFilePath, configuration.rootOutputDirectory + page.relativeOutputPath)
        
        
        let context: [String: Any] = [
            "recentPosts": recentPosts,
            "feedItems": rssFeedItems,
            "posts": posts,
            ]
        let pageHTML = try renderBody(source: page, context: context)
        
        var rendered: String = ""
        if (page.type == PageType.plain) {
            rendered = pageHTML
        } else {
            // markdown or HTML, use template
            
            let context: [String: Any] = [
                "site": configuration.siteContext,
                
                //        "title": "Title",
                "content": pageHTML,
                
//                "articles": [
//                    //            Article(title: "Migrating from OCUnit to XCTest", author: "Kyle Fuller"),
//                    //            Article(title: "Memory Management with ARC", author: "Kyle Fuller"),
//                ]
            ]
            
            rendered = try environment.renderTemplate(string: template, context: context)
        }
        
        try outputFilePath.parent.createDirectory()
        
        print("created dir \(outputFilePath.parent)")
        
        for asset in page.assetsToCopy {
            print("copy \(asset.inputPath) to \(outputFilePath.parent + asset.outPath)")
            try asset.inputPath.copyFile(to: outputFilePath.parent + asset.outPath)
        }
        
        try rendered.write(to: outputFilePath.url, atomically: true, encoding: .utf8)
        
        // print("Downloaded file: \(outputName) \n \(htmlFromMarkdown)")
        print("written HTML to \(outputFilePath.rawValue)")
    }
}

public enum PageType {
    case plain
    case markdown
    case html
}

struct WebPageSource {
    public let fullSourcePath: Path
    
    /// including file extenstion
    public let relativeOutputPath: Path
    
    public let type: PageType
    
    public let assetsToCopy: [StaticFileMapping]
}

public enum SourceError: Error {
    case AnyError
}

func typeForExtension(_ fileExtension: String) -> PageType {
    switch fileExtension {
        case "md":
        return .markdown;
        case "html":
        return .html;
        default:
        return .plain;
    }
}

func readPageSources(directory: Path, outputPrefixFolder prefix: Path?) throws -> [WebPageSource] {
    guard directory.isDirectoryFile else {
        throw SourceError.AnyError
    }
    
    let indexFilesInFolder = directory.find(searchDepth: 0) { path in
        path.isDirectory && (path + Path("./index.md")).exists
    }.map { $0 + Path("./index.md") }
    
    let plainFiles = directory.find(searchDepth: 0) { path in
        path.pathExtension == "md" || path.pathExtension == "html" || path.pathExtension == "xml"
    }

    let plainFileSources: [WebPageSource] = plainFiles.map {
        filePath in
        
        let fileExtension = filePath.pathExtension == "xml" ? "xml" : "html";
        let pageType = typeForExtension(filePath.pathExtension);
        
        let fileName = getOutputNameFromFilename(filePath.fileName.replacingOccurrences(of: ".\(filePath.pathExtension)", with: ""))
        let fileNamePath = Path("./\(fileName).\(fileExtension)");
        
        let outputPath = prefix != nil ? prefix! + fileNamePath : fileNamePath;
        
        print("webpage source out", outputPath)
        
        return WebPageSource(fullSourcePath: filePath, relativeOutputPath: outputPath, type: pageType, assetsToCopy: [])
    }
    
    
    let folderBasedSources: [WebPageSource] = indexFilesInFolder.map {
        path in
        
        let fileName = getOutputNameFromFilename(path.parent.fileName)
        let fileNamePath = Path("./\(fileName)/index.html");
        
        let outputPath = prefix != nil ? prefix! + fileNamePath : fileNamePath
        
        print(fileNamePath)
//        fatalError()
        
        let assetsToCopy = path.parent.find(searchDepth: 0) {
            filepath in
            return filepath != path
            }.map {
                filepath in
                return StaticFileMapping(inputPath: filepath, outPath: Path("./\(filepath.fileName)"))
        }
        
        return WebPageSource(fullSourcePath: path, relativeOutputPath: outputPath, type: typeForExtension("md"), assetsToCopy: assetsToCopy)
    }
    
    return plainFileSources + folderBasedSources
    
//    return []
}

// TODO: private, import with testable to tests
public func getOutputNameFromFilename(_ fileName: String) -> String {
    guard let match = fileName.range(of: "^\\d{4}-\\d{2}-\\d{2}[ -]", options: .regularExpression) else {
        //        print("plain filename")
        return fileName; // .replacingOccurrences(of: ".md", with: "")
    }
    
    let nameWithoutDate = String(fileName[match.upperBound...]);
    
    let nameWithoutSpaces = nameWithoutDate.replacingOccurrences(of: " ", with: "-")
    
    //    if (namewith)
    
    /// let indexEndOfText = template.index(template.endIndex, offsetBy: -3)
    //    print(match)
    //    print("starts with date")
    return nameWithoutSpaces; // .replacingOccurrences(of: ".md", with: "")
}

public func nameFromFilePath(_ filePath: String) -> String? {
    guard let match = filePath.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) else {
        //        print("plain filename")
        return nil; // .replacingOccurrences(of: ".md", with: "")
    }
    
    let date = String(filePath[match.lowerBound..<match.upperBound]);
    
    return date
}

public func titleFromPostMarkdown(_ filePath: Path) -> String? {
    do {
        let fileContents = try String(contentsOf: filePath.url, encoding: .utf8)
        
        let re = try NSRegularExpression(pattern: "# (.+)", options: [])
        let matches = re.matches(in: fileContents, range: NSRange(location: 0, length: fileContents.utf16.count))
        
        print("number of matches: \(matches.count)")
        
        for match in matches as [NSTextCheckingResult] {
            // range at index 0: full match
            // range at index 1: first capture group
            let substring = (fileContents as NSString).substring(with: match.range(at: 1))
            
            print(substring)
            
            return substring
        }
    } catch {
        // nothing
    }

//
//    guard let match = filePath.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) else {
//        //        print("plain filename")
//        return nil; // .replacingOccurrences(of: ".md", with: "")
//    }
//    
//    filePath.rangeof
//    
//    let date = String(filePath[match.lowerBound...match.upperBound]);
//    
//    return date
    return nil
}

func convertFootnotes(input: String) throws -> String {
    var text = input
    var handledFootnotes = Set<String>()
    let re = try NSRegularExpression(pattern: "\\[\\^([^\\]]+)\\]", options: [])
    
    var startChar = 0
    
    while let firstMatch = re.firstMatch(in: text, options: [], range: NSRange(location: startChar, length: text.utf16.count - startChar)) {
        let firstMatchRange = firstMatch.range(at: 1)
        startChar = firstMatchRange.upperBound
        let footnoteIdentifier = (text as NSString).substring(with: firstMatchRange)
        
        handledFootnotes.insert(footnoteIdentifier)
        
        text = (text as NSString).replacingCharacters(in: firstMatch.range, with: "<sup id=\"fa_\(footnoteIdentifier)\">[\(footnoteIdentifier)](#fn_\(footnoteIdentifier))</sup>")
        
        print(footnoteIdentifier)
        
        // Now find the matching part
        
        let footnoteExpression = try NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: "[^\(footnoteIdentifier)]:"), options: [])
        if let footnoteMatch = footnoteExpression.firstMatch(in: text, options: [], range: NSRange(location: startChar, length: text.utf16.count - startChar)) {
            let footnoteText = "<b id=\"fn_\(footnoteIdentifier)\">\(footnoteIdentifier)</b> [↩](#fa_\(footnoteIdentifier))" // TODO: Should include content, and link to go up afterwards
            text = (text as NSString).replacingCharacters(in: footnoteMatch.range, with: footnoteText)
        }
        
//        print(startChar)
//        print(text.utf16.count)
    }
    
//    re.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
//
//
//
//    if let firstMatch = re.firstMatch(in: input, options: [], range: NSRange(location: startChar, length: input.utf16.count)) {
//
//    }
    
//    re.
    // let matches = re.matches(in: fileContents, range: NSRange(location: 0, length: fileContents.utf16.count))
    
    
    
    /**
     Bla bla <sup id="a1">[1](#f1)</sup>
     Then from within the footnote, link back to it.
     
     
 */
    return text
}

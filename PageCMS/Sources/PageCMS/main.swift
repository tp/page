import SwiftMarkdown
import Stencil
import PageCMSLib

struct Article {
    let title: String
    let date: String
    let url: String
}
//
//let context = [
//    "articles": [
//        Article(title: "Migrating from OCUnit to XCTest", author: "Kyle Fuller"),
//        Article(title: "Memory Management with ARC", author: "Kyle Fuller"),
//    ]
//]
//
//let environment = Environment(loader: FileSystemLoader(paths: ["templates/"]))
//let articleTemplate = """
//There are {{ articles.count }} articles.
//
//<ul>
//{% for article in articles %}
//<li>{{ article.title }} by {{ article.author }}</li>
//{% endfor %}
//</ul>
//"""
//
//let rendered = try environment.renderTemplate(string: articleTemplate, context: context)
//
//print(rendered)

import FileKit

import Foundation

// main
// create & setup output directories
let distDirectoy = Path("/Users/timm/Projects/github/tp.github.com/dist/")
//try distDirectoy.createDirectory()
try (distDirectoy + "articles").createDirectory()
try Path("/Users/timm/Projects/github/tp.github.com/CNAME").copyFile(to: distDirectoy + "CNAME")

//;e
let articles = try readPageSources(directory: Path("/Users/timm/Projects/github/tp.github.com/articles/"), outputPrefixFolder: "articles") // TODO: New "Post" struct, ability to overwrite URLs from within the file? (In order to support/enforce legacy URLs?) Or maybe just have multiple sources, and then merge them into a common `posts`
// TODO: Create redirects from Symlinks ?
let mainPages = try readPageSources(directory: Path("/Users/timm/Projects/github/tp.github.com/"), outputPrefixFolder: nil)

print(articles)
print("main pages")
print(mainPages)

let mostRecentArticles: [[String: Any]] = [];

let environment = Environment()
let template = try String(contentsOf: Path("/Users/timm/Projects/github/tp.github.com/_layouts/default.html").url, encoding: .utf8)

let recentPosts: [Article] = Array(articles.map {
    x -> Article in
    let url = x.relativeOutputPath.rawValue.replacingOccurrences(of: "./", with: "/").replacingOccurrences(of: ".html", with: "");
    let date = nameFromFilePath(x.fullPath.rawValue) ?? "1970-01-01"
    let title = titleFromPostMarkdown(x.fullPath) ?? "No title"
    
    return Article(title: title, date: date, url: url)
}.sorted {
    a, b in
    return a.date > b.date;
}.prefix(5))

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
    
    let escapedTitle: String = {
        return CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, post.title as CFString, "[]." as CFString,":/?&=;+!@#$()',*" as CFString,CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue))
        }() as String!
    
    
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
    
    return RssItem(title: escapedTitle, excerpt: "", rssDate: rssDate, isoDate: isoDate, url: post.url, id: post.url)
}

for page in (articles + mainPages) {
    let outputFilePath = distDirectoy + page.relativeOutputPath

    var pageHTML: String = ""
    if (page.type == PageType.markdown) {
        let markdownSource = try String(contentsOf: page.fullPath.url, encoding: .utf8)
        pageHTML = try markdownToHTML(markdownSource, options: [])
    } else {
        // plain or HTML
        
        let fileContents = try String(contentsOf: page.fullPath.url, encoding: .utf8)
        
        let context: [String: Any] = [
            "recentPosts": recentPosts,
            "feedItems": rssFeedItems
        ]
        
        pageHTML = try environment.renderTemplate(string: fileContents, context: context)
    }
    
    var rendered: String = ""
    if (page.type == PageType.plain) {
        rendered = pageHTML
    } else {
        // markdown or HTML, use template
        
        let context: [String: Any] = [
            "page": [
                "title": "Timm Preetz",
            ],
            
            //        "title": "Title",
            "content": pageHTML,
            
            "articles": [
                //            Article(title: "Migrating from OCUnit to XCTest", author: "Kyle Fuller"),
                //            Article(title: "Memory Management with ARC", author: "Kyle Fuller"),
            ]
        ]
        
        rendered = try environment.renderTemplate(string: template, context: context)
    }

    try rendered.write(to: outputFilePath.url, atomically: true, encoding: .utf8)
    
    // print("Downloaded file: \(outputName) \n \(htmlFromMarkdown)")
    print("written HTML to \(outputFilePath.rawValue)")
}







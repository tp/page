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

let recentPosts: [Article] = articles.map {
    x in
    let url = x.relativeOutputPath.rawValue.replacingOccurrences(of: "./", with: "/").replacingOccurrences(of: ".html", with: "");
    let date = nameFromFilePath(x.fullPath.rawValue) ?? "1970-01-01"
    let title = titleFromPostMarkdown(x.fullPath) ?? "No title"
    
    return Article(title: title, date: date, url: url)
}.sorted {
    a, b in
    return a.date > b.date;
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
            "recentPosts": recentPosts
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







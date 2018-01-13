print("Hello, world 1!")

import SwiftMarkdown
let markdown = "# Hello"
let html = try markdownToHTML(markdown)
print(html) // This will return "<h1>Hello</h1>\n"

import Stencil
import PageCMSLib

//struct Article {
//    let title: String
//    let author: String
//}
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

let distDirectoy = Path("/Users/timm/Projects/github/tp.github.com/dist/")
try distDirectoy.createDirectory()

try (distDirectoy + "articles").createDirectory()

try Path("/Users/timm/Projects/github/tp.github.com/CNAME").copyFile(to: distDirectoy + "CNAME")
//try Path("/Users/timm/Projects/github/tp.github.com/index.html").copyFile(to: distDirectoy + "index.html")

let textFiles = Path("/Users/timm/Projects/github/tp.github.com/").find(searchDepth: 0) { path in
    path.pathExtension == "md"
} // -> map these to the root

let postFiles = Path("/Users/timm/Projects/github/tp.github.com/articles/_posts/").find(searchDepth: 3) { path in
    path.pathExtension == "md"
} // create entries for them in the /articles folder

//let documents = Path.userDocuments.find(searchDepth: 1) { path in
//    String(path)
//}

print(textFiles)
print(postFiles)

import Foundation

//func getOutputNameFromFilename(_ fileName: String) -> String {
//    guard let match = fileName.range(of: "^\\d{4}-\\d{2}-\\d{2}[ -]", options: .regularExpression) else {
////        print("plain filename")
//        return fileName.replacingOccurrences(of: ".md", with: "")
//    }
//
//    let nameWithoutDate = String(fileName[match.upperBound...]);
//
//    let nameWithoutSpaces = nameWithoutDate.replacingOccurrences(of: " ", with: "-")
//
////    if (namewith)
//
//    /// let indexEndOfText = template.index(template.endIndex, offsetBy: -3)
////    print(match)
////    print("starts with date")
//    return nameWithoutSpaces.replacingOccurrences(of: ".md", with: "")
//}

func generateOutputFilePath(_ outputName: String, isArticle: Bool) -> Path {
    if (isArticle) {
           return distDirectoy + "articles" + (outputName.appending(".html"))
    } else {
        return distDirectoy + (outputName.appending(".html"))
    }
}

let environment = Environment(loader: FileSystemLoader(paths: ["templates/"]))
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

let template = try String(contentsOf: Path("/Users/timm/Projects/github/tp.github.com/_layouts/default.html").url, encoding: .utf8)

for download in (textFiles + postFiles) {
    // output file name
    let outputName = getOutputNameFromFilename(download.fileName)
//    let htmlFromMarkdown = try markdownToHTML(download.fileHandleForReading!.readDataToEndOfFile().enco)
    
    
    var markdownSource = try String(contentsOf: download.url, encoding: .utf8)
    if (outputName == "index") {
        // re-run through templating engine
        
        let context: [String: Any] = [
            "recentPosts": [
                [
                    "date": "adsf",
                    "title": "asdf",
                    "url": "/test",
                ],
                [
                    "date": "adsf",
                    "title": "asdf",
                    "url": "/test",
                ]
            ] // date, title, url | date: "%Y-%m-%d"
        ]
        
        print("before")
        print(markdownSource)
        
        markdownSource = try environment.renderTemplate(string: markdownSource, context: context)
        
        print("after templating")
        print(markdownSource)
    }
    
    let htmlFromMarkdown = try markdownToHTML(markdownSource, options: [])
    
    let outputFilePath = generateOutputFilePath(outputName, isArticle: download.rawValue.contains("articles"))
    
    let context: [String: Any] = [
        "page": [
            "title": "Timm Preetz",
        ],

//        "title": "Title",
        "content": htmlFromMarkdown,

        "articles": [
//            Article(title: "Migrating from OCUnit to XCTest", author: "Kyle Fuller"),
//            Article(title: "Memory Management with ARC", author: "Kyle Fuller"),
        ]
    ]
    
    let rendered = try environment.renderTemplate(string: template, context: context)
    
    
    try rendered.write(to: outputFilePath.url, atomically: true, encoding: .utf8)
    
//    print("Downloaded file: \(outputName) \n \(htmlFromMarkdown)")
    print("written HTML to \(outputFilePath.rawValue)")
}



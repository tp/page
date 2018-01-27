//
//  file-provider.swift
//  page-cmsPackageDescription
//
//  Created by Timm Preetz on 11.01.18.
//

import Foundation
import FileKit

public enum PageType {
    case plain
    case markdown
    case html
}

public struct WebPageSource {
    public let fullPath: Path
    
    /// including file extenstion
    public let relativeOutputPath: Path
    
    public let type: PageType
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

public func readPageSources(directory: Path, outputPrefixFolder prefix: String?) throws -> [WebPageSource] {
    guard directory.isDirectoryFile else {
        throw SourceError.AnyError
    }
    
    let files = directory.find(searchDepth: 0) { path in
        path.pathExtension == "md" || path.pathExtension == "html" || path.pathExtension == "xml"
    }
    
    return files.map {
        filePath in
        
        let fileExtension = filePath.pathExtension == "xml" ? "xml" : "html";
        let pageType = typeForExtension(filePath.pathExtension);
        
        let fileName = getOutputNameFromFilename(filePath.fileName.replacingOccurrences(of: ".\(filePath.pathExtension)", with: ""))
        
        let outputPath = prefix != nil ? Path("./\(prefix!)/\(fileName).\(fileExtension)") :  Path("./\(fileName).\(fileExtension)")
               
        
        
        return WebPageSource(fullPath: filePath, relativeOutputPath: outputPath, type: pageType)
    }
    
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

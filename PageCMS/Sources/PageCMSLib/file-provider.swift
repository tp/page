//
//  file-provider.swift
//  page-cmsPackageDescription
//
//  Created by Timm Preetz on 11.01.18.
//

import Foundation
import FileKit

enum PageType {
    case plain
    case markdown
}

struct WebPageSource {
    let fullPath: Path
    
    /// including file extenstion
    let relativeOutputPath: Path
    
    let type: PageType
}

enum SourceError: Error {
    case AnyError
}

func readPageSources(directory: Path, prefix: String?) throws -> [WebPageSource] {
    guard directory.isDirectoryFile else {
        throw SourceError.AnyError
    }
    
    let files = Path("/Users/timm/Projects/github/tp.github.com/").find(searchDepth: 0) { path in
        path.pathExtension == "md" || path.pathExtension == "html" || path.pathExtension == "xml"
    }
    
    return files.map {
        filePath in
        
        let fileExtension = filePath.pathExtension == "xml" ? "xml" : "html";
        let pageType = filePath.pathExtension == "md" ? PageType.markdown : PageType.plain;
        
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

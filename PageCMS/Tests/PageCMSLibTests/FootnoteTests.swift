//
//  FootnoteTests.swift
//  PageCMSPackageDescription
//
//  Created by Timm Preetz on 03.03.18.
//

import Foundation

@testable import PageCMSLib
import XCTest
import FileKit

class FootnoteTests: XCTestCase {
    
//    asdf
//
//    //    let client = GetClient()
//
    func testFootnoteConversion() throws {
        let input = """
            Foo bar[^1].
        
            [^1]: Footnote
        """
        
        let expectedOutput = """
            Foo bar<sup id="fa_1">[1](#fn_1)</sup>.

            <b id="fn_1">1</b> [↩](#fa_1) Footnote
        """
        
        let output = try PageCMSLib.convertFootnotes(input: input)
        
        XCTAssertEqual(expectedOutput, output)
        
        
//        let filePathString = "/Users/timm/Projects/github/tp.github.com/atom.xml"
//
//        let path = Path(filePathString)
//
//        XCTAssertEqual(path.isAbsolute, true)
//        XCTAssertEqual(path.isDirectoryFile, false)
//        XCTAssertEqual(path.isDirectory, false)
//
//        XCTAssertEqual(path.fileName, "atom.xml")
//        XCTAssertEqual(path.pathExtension, "xml")
    
        //        let result = client.fetch("http://httpbin.org/status/419")
        //        XCTAssertEqual("240", "419", "Incorrect value received from server")
    }
    

}

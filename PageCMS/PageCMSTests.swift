
import Foundation
import XCTest
//import Files
//import CommandLineToolCore
@testable import PageCMS
import FileKit

class PageCMSTests: XCTestCase {
    func filekitPathHandling() throws {
        let pathString = "/Users/timm/Projects/github/tp.github.com/atom.xml"
        
        let path = Path(pathString)
        
        XCTAssertEqual(path.isAbsolute, true)
        
        XCTAssertEqual(path.isDirectoryFile, false)
        XCTAssertEqual(path.isDirectory, false)
        
        XCTAssertEqual(path.fileName, "atom")
        XCTAssertEqual(path.pathExtension, "xml")
        
        // Setup a temp test folder that can be used as a sandbox
//        let fileSystem = FileSystem()
//        let tempFolder = fileSystem.temporaryFolder
//        let testFolder = try tempFolder.createSubfolderIfNeeded(
//            withName: "CommandLineToolTests"
//        )
//
//        // Empty the test folder to ensure a clean state
//        try testFolder.empty()
//
//        // Make the temp folder the current working folder
//        let fileManager = FileManager.default
//        fileManager.changeCurrentDirectoryPath(testFolder.path)
//
//        // Create an instance of the command line tool
//        let arguments = [testFolder.path, "Hello.swift"]
//        let tool = CommandLineTool(arguments: arguments)
//
//        // Run the tool and assert that the file was created
//        try tool.run()
        XCTAssertNotNil(nil)
    }

    // class cmsTests: XCTestCase {
    // func testExample() {
    //     // This is an example of a functional test case.
    //     // Use XCTAssert and related functions to verify your tests produce the correct
    //     // results.
    //     XCTAssertEqual(cms().text, "Hello, World!")
    // }


    static var allTests = [
        ("filekitPathHandling", filekitPathHandling),
    ]
// }
}

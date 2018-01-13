//@testable import PageCMS
import PageCMSLib
import XCTest
import FileKit

class SimpleGetTests: XCTestCase {
    
//    let client = GetClient()
    
    func testFileKitExpectations() {
        let filePathString = "/Users/timm/Projects/github/tp.github.com/atom.xml"
        
        let path = Path(filePathString)
        
        XCTAssertEqual(path.isAbsolute, true)
        XCTAssertEqual(path.isDirectoryFile, false)
        XCTAssertEqual(path.isDirectory, false)
        
        XCTAssertEqual(path.fileName, "atom.xml")
        XCTAssertEqual(path.pathExtension, "xml")
        
//        let result = client.fetch("http://httpbin.org/status/419")
//        XCTAssertEqual("240", "419", "Incorrect value received from server")
    }
    
    func testOutputFilenameGeneration() {
        XCTAssertEqual(getOutputNameFromFilename("2018-12-01 Test-foo"), "Test-foo")
        XCTAssertEqual(getOutputNameFromFilename("2018-12-01-test-foo"), "test-foo")
        XCTAssertEqual(getOutputNameFromFilename("Bar Baz"), "Bar-Baz")
    }
}

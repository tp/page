import PageCMSLib
import FileKit
import Foundation

let cwd = FileManager.default.currentDirectoryPath

print("CWD: \(cwd)")

let configuration = SiteConfiguration(
    rootOutputDirectory:  Path("\(cwd)/../dist/"),
    siteContext: [
        "title": "Timm Preetz",
        "description": "Personal page",
    ],
    articleMappings: [
        ArticleMapping(sourceDirectoryPath: Path("\(cwd)/../articles/"), outputDirectoryPrefix: Path("./articles"))
    ],
    pageMappings: [
        PageMapping(sourceDirectoryPath: Path("\(cwd)/.."), outputDirectoryPrefix: Path("./"))
    ],
    staticFileMappings: [
        StaticFileMapping(inputPath: Path("\(cwd)/../CNAME"), outPath: Path("./CNAME"))
    ]
);

try generateSite(configuration);

import PageCMSLib
import FileKit

let configuration = SiteConfiguration(
    rootOutputDirectory: Path("/Users/timm/Projects/github/tp.github.com/dist/"),
    siteContext: [
        "title": "Timm Preetz",
        "description": "Personal page",
    ],
    articleMappings: [
        ArticleMapping(sourceDirectoryPath: Path("/Users/timm/Projects/github/tp.github.com/articles/"), outputDirectoryPrefix: Path("./articles"))
    ],
    pageMappings: [
        PageMapping(sourceDirectoryPath: Path("/Users/timm/Projects/github/tp.github.com/"), outputDirectoryPrefix: Path("./"))
    ],
    staticFileMappings: [
        StaticFileMapping(inputPath: Path("/Users/timm/Projects/github/tp.github.com/CNAME"), outPath: Path("./CNAME"))
    ]
);

try generateSite(configuration);

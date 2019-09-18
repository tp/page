// ReactDOMServer.renderToStaticMarkup(element)
import * as fs from "fs-extra";
import * as path from "path";
import * as MarkdownIt from "markdown-it";
import * as ReactDOMServer from "react-dom/server";
import * as React from "react";
import { Template } from "./template";
import { Homepage, ArticleInfo, Archive } from "./homepage";
import * as Prism from "prismjs";
var loadLanguages = require("prismjs/components/");
loadLanguages(["typescript", "go", "swift", "rust", "dart"]);

// Returns a highlighted HTML string

async function* sourceFiles(
  folder: string,
  recourse: boolean
): AsyncIterableIterator<string> {
  for (const entry of await fs.readdir(folder)) {
    const entryPath = path.join(folder, entry);
    if ((await fs.stat(entryPath)).isDirectory() && recourse) {
      yield* sourceFiles(entryPath, recourse);
    } else {
      yield entryPath;
    }
  }
}

async function main() {
  const md = new MarkdownIt({
    html: true,
    linkify: false,
    typographer: true,
    highlight: function (str, lang) {
      if (lang) {
        try {
          return Prism.highlight(str, Prism.languages[lang]);
        } catch (__) { }
      }

      return ""; // use external default escaping
    }
  }).use(require("markdown-it-footnote"));

  // articles
  const articleInfos: ArticleInfo[] = [];

  await fs.ensureDir("./dist/articles");

  for await (const filePath of sourceFiles("./content/articles", true)) {
    if (!filePath.endsWith(".md")) {
      continue;
    }
    const isIndex = filePath.endsWith("index.md");
    // if (!isIndex) {
    //   continue;
    // }

    console.error(filePath);

    const file = await fs.readFile(filePath, "utf-8");

    const contentHTML = md.render(file);

    const tokens = md.parse(file, {});
    let title = "";
    {
      let titleOpen = false;
      for (const token of tokens) {
        if (token.type === "heading_open" && token.tag === "h1") {
          titleOpen = true;
        } else if (titleOpen) {
          if (token.type === "heading_close") {
            break;
          } else if (token.type === "inline") {
            title += token.content;
          }
        }
      }
    }

    console.error();

    const dateFromFileName = path
      .basename(filePath.replace("/index", ""))
      .substring(0, 10);
    const date = new Date(dateFromFileName);

    const articleInfo = {
      title,
      date,
      link: filePath
        .replace("content/", "")
        .replace(`${dateFromFileName}-`, "")
        .replace(".md", "")
        .replace("/index", "")
    };

    articleInfos.push(articleInfo);

    const rendered = ReactDOMServer.renderToStaticMarkup(
      <Template innerHTML={contentHTML} title={title} />
    );

    const outputPath = path.join("./dist", articleInfo.link + ".html");

    if (isIndex) {
      const indexInputFolder = path.join(filePath, "../");
      const indexOutputFolder = path.join(outputPath, "../");

      console.error(`indexFileFolder`, indexInputFolder, indexOutputFolder);
      await fs.copy(indexInputFolder, indexOutputFolder, { recursive: true });
    }

    await fs.writeFile(outputPath, rendered);

    console.error(dateFromFileName, date, title, outputPath);
  }

  for await (const filePath of sourceFiles("./content", false)) {
    if (!filePath.endsWith(".md")) {
      continue;
    }

    // if (!isIndex) {
    //   continue;
    // }

    console.error(filePath);

    const file = await fs.readFile(filePath, "utf-8");

    const contentHTML = md.render(file);

    const tokens = md.parse(file, {});
    let title = "";
    {
      let titleOpen = false;
      for (const token of tokens) {
        if (token.type === "heading_open" && token.tag === "h1") {
          titleOpen = true;
        } else if (titleOpen) {
          if (token.type === "heading_close") {
            break;
          } else if (token.type === "inline") {
            title += token.content;
          }
        }
      }
    }

    const link = filePath.replace("content/", "").replace(".md", "");

    const rendered = ReactDOMServer.renderToStaticMarkup(
      <Template innerHTML={contentHTML} title={title} />
    );

    const outputPath = path.join("./dist", link + ".html");

    await fs.writeFile(outputPath, rendered);

    console.error(title, outputPath);
  }

  await fs.writeFile(
    "./dist/index.html",
    ReactDOMServer.renderToStaticMarkup(
      <Template
        innerHTML={ReactDOMServer.renderToStaticMarkup(
          <Homepage articles={articleInfos} />
        )}
        title="Home"
      />
    )
  );
  await fs.writeFile(
    "./dist/archive.html",
    ReactDOMServer.renderToStaticMarkup(
      <Template
        innerHTML={ReactDOMServer.renderToStaticMarkup(
          <Archive articles={articleInfos} />
        )}
        title="Archive"
      />
    )
  );
  await fs.writeFile("./dist/rss.xml", feed(articleInfos));

  await fs.copy("./assets", "./dist/assets", { recursive: true });

  console.error(`ReactDOMServer.renderToStaticMarkup(element)`);
}

main();

function feed(articlesInfos: ArticleInfo[]) {
  const latestArticles = articlesInfos
    .slice()
    .sort((a, b) => b.date.valueOf() - a.date.valueOf())
    .slice(0, 5);

  return `<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
 <title>Timm Preetz</title>
 <description>Thoughts on code.</description>
 <link>https://timm.preetz.name/</link>
 <atom:link href="https://timm.preetz.name/rss.xml" rel="self" type="application/rss+xml" />

 ${latestArticles.map(article => {
    return `
   <item>
    <title><![CDATA[${article.title}]]></title>
    <description><![CDATA[${""}]]></description>
    <link>https://timm.preetz.name/${article.link}</link>
    <guid isPermaLink="false">${article.link}</guid>
    <pubDate>${article.date.toUTCString()}</pubDate>
   </item>`;
  }).join('\n')}

</channel>
</rss>`;
}

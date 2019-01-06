// ReactDOMServer.renderToStaticMarkup(element)
import * as fs from "fs-extra";
import * as path from "path";
import * as MarkdownIt from "markdown-it";
import * as ReactDOMServer from "react-dom/server";
import * as React from "react";
import { Template } from "./template";

interface ArticleInfo {
  title: string;
  date: Date;
  link: string;
}

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
  //   yield "asd";
}

async function main() {
  const md = new MarkdownIt({
    html: true,
    linkify: false,
    typographer: false
  }).use(require("markdown-it-footnote"));

  // articles
  const articleInfos: ArticleInfo[] = [];
  for await (const filePath of sourceFiles("./content/articles", false)) {
    if (!filePath.endsWith(".md")) {
      continue;
    }

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

    const dateFromFileName = path.basename(filePath).substring(0, 10);
    const date = new Date(dateFromFileName);

    const articleInfo = {
      title,
      date,
      link: filePath
        .replace("content/", "")
        .replace(`${dateFromFileName}-`, "")
        .replace(".md", "")
    };

    articleInfos.push(articleInfo);

    const rendered = ReactDOMServer.renderToStaticMarkup(
      <Template innerHTML={contentHTML} title={title} />
    );

    const outputPath = path.join("./dist", articleInfo.link + ".html");

    await fs.writeFile(outputPath, rendered);
    console.error(dateFromFileName, date, title, outputPath);
  }

  // console.error(articleInfo);

  //   md.parse()
  //   console.error(sourceFiles());

  console.error(`ReactDOMServer.renderToStaticMarkup(element)`);
}

main();

import * as React from "react";

export interface ArticleInfo {
  title: string;
  date: Date;
  link: string;
}

interface HomepageProps {
  articles: ArticleInfo[];
}

export function Homepage(props: HomepageProps) {
  const mostRecentArticles = props.articles
    .slice()
    .sort((a, b) => b.date.valueOf() - a.date.valueOf())
    .slice(0, 5);

  return (
    <div className="homepageOverview">
      <div className="recentPosts" style={{ fontFamily: "Courier" }}>
        <h3>Recent Posts:</h3>
        <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
          {mostRecentArticles.map((article, i) => {
            return (
              <li key={i}>
                <span>{article.date.toISOString().substring(0, 10)}</span>
                <br />
                <a href={article.link} className="postTitle">
                  {article.title}
                </a>
                <br />
                <br />
              </li>
            );
          })}
        </ul>
      </div>
      <a href="/rss.xml">RSS Feed</a> | <a href="/archive">Archive</a>
    </div>
  );
}

export function Archive(props: HomepageProps) {
  const mostRecentArticles = props.articles
    .slice()
    .sort((a, b) => b.date.valueOf() - a.date.valueOf());

  return (
    <>
      <h2>Archive</h2>
      <ul style={{ listStyleType: "none", paddingLeft: 0, marginLeft: 0 }}>
        {mostRecentArticles.map((article, i) => {
          return (
            <li
              key={i}
              style={{
                whiteSpace: "nowrap",
                textOverflow: "ellipsis",
                overflow: "hidden"
              }}
            >
              <a
                style={{ textDecoration: "none", fontFamily: "Futura" }}
                href={"/" + article.link}
              >
                <span style={{ fontFamily: "monospace" }}>
                  {article.date.toISOString().substring(0, 10)}{" "}
                </span>
                {article.title}
              </a>
            </li>
          );
        })}
      </ul>
    </>
  );
}

import * as React from "react";

export interface TemplateProps {
  innerHTML: string;
  title: string;
}

export function Template(props: TemplateProps): JSX.Element {
  return (
    <html>
      <Head title={props.title} />
      <body>
        <Navigation />

        <div id="mainWrapper" className="grt">
          <div className="contentWrapper">
            <div dangerouslySetInnerHTML={{ __html: props.innerHTML }} />
          </div>
        </div>
      </body>
    </html>
  );
}

function Navigation() {
  return (
    <div id="navWrapper">
      <nav>
        <a href="/" style={{ marginRight: 20 }}>
          <img
            src="/assets/ava.jpg"
            width="30"
            height="30"
            style={{ marginTop: 5, float: "left", borderRadius: 2 }}
          />
        </a>
        <a href="/projects">Projects</a>
        {"      "}
        <a href="/archive">Archive</a>
        {"      "}
        <a href="/about">About</a>
      </nav>
    </div>
  );
}

interface HeaderProps {
  title: string;
}

function Head(props: HeaderProps) {
  return (
    <head>
      <meta httpEquiv="content-type" content="text/html;charset=utf-8" />
      <title>{props.title} | Timm Preetz</title>
      <Style />
      <link rel="stylesheet" href="/assets/highlightjs.css" />
    </head>
  );
}

function Style() {
  const css = ``;

  return <style dangerouslySetInnerHTML={{ __html: css }} />;
}

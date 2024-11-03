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
        <a href="/">
          <img
            src="/assets/timm_head_ava.jpg"
            width="30"
            height="30"
            className="headerImage"
          />

          <div className="name">Timm Preetz</div>
        </a>

        <div>
          <a href="/projects">Projects</a>
          <a href="/archive">Archive</a>
          <a href="/about">About</a>
        </div>
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
      <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover"
      />

      <link rel="stylesheet" href="/assets/highlightjs.css" />
      <link rel="alternate" type="application/rss+xml" title="Timm Preetz's blog" href="/rss.xml" />
      <link rel="apple-touch-icon" sizes="180x180" href="/assets/favicon/apple-touch-icon.png" />
      <link rel="icon" type="image/png" sizes="32x32" href="/assets/favicon/favicon-32x32.png" />
      <link rel="icon" type="image/png" sizes="16x16" href="/assets/favicon/favicon-16x16.png" />
      <link rel="manifest" href="/assets/favicon/site.webmanifest" />
    </head>
  );
}

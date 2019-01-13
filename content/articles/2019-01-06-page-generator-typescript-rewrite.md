# Page Generator TypeScript Rewrite

After switching away from Jekyll (since I have no familiarity with Ruby and was running into limitations of how to structure this site), I wrote my custom static page generator in Swift. I choose Swift because I had been meaning to explore the language, but had no Apple-platform project on the horizon and thought it might be as good as any language to convert Markdown and write some static files.

But after the initial creation I never touched it much. Development always felt a little heavy and slow and I wasn't content with the libraries and approach I picked.

So this weekend I took the to rewriting the page generation to TypeScript. Since it's currently my main development environment, it was quick to get the basics up and running. For now it's just a static site generation, with no client side rendering.  
Though I'd love to add that in the future to have a personal project with SSR + CSR to better explore different approaches here.

I was delighted how for every problem I had (React instead of templating, Markdown, code syntax highlighting, file access) there were already solid libraries to choose from. Some I'd liked to be a little different, but overall this toolset is extremely practical.

In the end the whole code base is just 515 lines (in its first draft, without any code-level compression applied) and contains all the flexibility and customization I desire. And I can build and run the application to generate all pages in under a second ☺️.

// ~/.finicky.js

module.exports = {
  defaultBrowser: "Google Chrome",
  rewrite: [
    {
      // Redirect all urls to use https
      match: ({ url }) => url.protocol === "http",
      url: { protocol: "https" }
    }
  ],
  handlers: [
    {
      // Open ON24 in Google Chrome Beta
      match: finicky.matchHostnames(["on24.com"]),
      browser: "Google Chrome Beta"
    },
    {
      // Open SO classrooms in Google Chrome Beta
      match: finicky.matchHostnames(["classroom.superorbital.io"]),
      browser: "Google Chrome Beta"
    },
    {
      // Open apple.com urls in Safari
      match: finicky.matchHostnames(["apple.com"]),
      browser: "Safari"
    },
    {
      // Open mozilla.org urls in Firefox
      match: finicky.matchHostnames(["mozilla.org"]),
      browser: "Firefox"
    },
    {
      // Open any url that includes the string "firefox" in Firefox
      match: "/firefox/",
      browser: "Firefox"
    },
    {
      // Open google.com and *.google.com urls in Google Chrome
      match: [
        "google.com/*", // match google.com urls
        "*.google.com/*", // match google.com subdomains
      ],
      browser: "Google Chrome"
    }
  ]
};


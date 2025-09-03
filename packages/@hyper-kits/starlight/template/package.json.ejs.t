---
to: <%= projectFolder %>/package.json
---
{
  "name": "<%= projectName %>-docs",
  "version": "1.0.0",
  "description": "Documentation site for <%= projectName %>",
  "type": "module",
  "scripts": {
    "build": "astro build",
    "dev": "astro dev",
    "preview": "astro preview",
    "astro": "astro"
  },
  "dependencies": {
    "astro-d2": "^0.8.0",
    "starlight-llms-txt": "^0.6.0"<% if (!enableAutoSidebar) { %>,
    "starlight-sidebar-topics": "^0.6.0"<% } %><% if (enableTypedoc) { %>,
    "starlight-typedoc": "^0.21.3"<% } %><% if (enableOpenAPI) { %>,
    "starlight-openapi": "^0.12.0"<% } %><% if (enableKeyboardShortcuts) { %>,
    "starlight-kbd": "^0.2.0"<% } %><% if (enableAutoSidebar) { %>,
    "starlight-auto-sidebar": "^0.3.0"<% } %><% if (enableScrollToTop) { %>,
    "starlight-scroll-to-top": "^0.2.0"<% } %><% if (enableChangelogs) { %>,
    "starlight-changelogs": "^0.2.0"<% } %><% if (enableObsidian) { %>,
    "starlight-obsidian": "^0.5.0"<% } %>
  },
  "devDependencies": {
    "@astrojs/starlight": "^0.35.2",
    "@astrojs/tailwind": "^6.0.2",
    "astro": "^5.13.3",
    "starlight-image-zoom": "^0.13.0",
    "starlight-links-validator": "^0.17.1",
    "tailwindcss": "^4.1.12"<% if (enableTypedoc) { %>,
    "typedoc": "^0.28.11",
    "typedoc-plugin-markdown": "^4.8.1"<% } %>
  }
}
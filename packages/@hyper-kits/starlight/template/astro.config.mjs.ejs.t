---
to: <%= projectFolder %>/astro.config.mjs
---
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightImageZoom from 'starlight-image-zoom';
import starlightLinksValidator from 'starlight-links-validator';
import starlightLLMsTxt from 'starlight-llms-txt';
import starlightSidebarTopics from 'starlight-sidebar-topics';
<% if (enableTypedoc) { %>import starlightTypeDoc from 'starlight-typedoc';<% } %>
<% if (enableOpenAPI) { %>import starlightOpenAPI from 'starlight-openapi';<% } %>
<% if (enableKeyboardShortcuts) { %>import starlightKbd from 'starlight-kbd';<% } %>
<% if (enableAutoSidebar) { %>import starlightAutoSidebar from 'starlight-auto-sidebar';<% } %>
<% if (enableScrollToTop) { %>import starlightScrollToTop from 'starlight-scroll-to-top';<% } %>
<% if (enableChangelogs) { %>import starlightChangelogs from 'starlight-changelogs';<% } %>
<% if (enableObsidian) { %>import starlightObsidian from 'starlight-obsidian';<% } %>
import d2 from 'astro-d2';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// https://astro.build/config
export default defineConfig({
  srcDir: './src',
  outDir: './dist-docs',
  publicDir: './public',
  site: '<%= siteUrl %>',
  base: '/',
  integrations: [
    d2(),
    starlight({
      plugins: [
        // Add image zoom functionality
        starlightImageZoom({}),
        // Validate internal links during build
        starlightLinksValidator(),
        // Generate LLMs.txt for AI consumption
        starlightLLMsTxt(),
        <% if (enableScrollToTop) { %>// Add scroll-to-top button
        starlightScrollToTop(),<% } %>
        <% if (enableKeyboardShortcuts) { %>// Document keyboard shortcuts
        starlightKbd(),<% } %>
        <% if (enableAutoSidebar) { %>// Automatic sidebar generation
        starlightAutoSidebar(),<% } else { %>// Organize sidebar with topics
        starlightSidebarTopics([
          {
            label: 'Documentation',
            link: '/introduction/',
            icon: 'document',
            items: [
              {
                label: 'Getting Started',
                items: [
                  { label: 'Introduction', link: '/introduction/' },
                  { label: 'Installation', link: '/installation/' },
                  { label: 'Quick Start', link: '/quick-start/' }
                ]
              },
              {
                label: 'Features',
                items: [
                  { label: 'Core Features', link: '/features/core/' }
                ]
              }
            ],
          },<% if (enableTypedoc) { %>
          {
            label: 'API Reference',
            link: '/api/readme/',
            icon: 'seti:config',
            items: [
              { label: 'API Overview', link: '/api/readme/' }
            ],
          },<% } %>
        ]),<% } %>
        <% if (enableOpenAPI) { %>// Generate OpenAPI/Swagger documentation
        starlightOpenAPI([
          {
            base: '/api',
            label: 'API',
            schema: resolve(__dirname, 'openapi.yaml'),
          },
        ]),<% } %>
        <% if (enableChangelogs) { %>// Display project changelogs
        starlightChangelogs({
          title: 'Changelog',
        }),<% } %>
        <% if (enableObsidian) { %>// Publish Obsidian vaults
        starlightObsidian(),<% } %>
        <% if (enableTypedoc) { %>// TypeDoc API documentation
        starlightTypeDoc({
          entryPoints: [resolve(__dirname, '<%= entryPoint %>')],
          tsconfig: resolve(__dirname, 'tsconfig.json'),
          output: 'api',
          typeDoc: {
            gitRevision: 'main',
          },
        }),<% } %>
      ],
      title: '<%= projectName %>',
      description: '<%= projectDescription %>',
      expressiveCode: {
        themes: ['tokyo-night'],
      },
      <% if (githubRepo) { %>social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: '<%= githubRepo %>',
        },
      ],
      editLink: {
        baseUrl: '<%= githubRepo %>/edit/main/',
      },<% } %>
      lastUpdated: true,
      favicon: '/favicon.ico',
    }),
  ],
});
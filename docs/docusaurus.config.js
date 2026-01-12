// @ts-check
import { themes as prismThemes } from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'gummyworm',
  tagline: 'Transform images into glorious ASCII art',
  favicon: 'img/favicon.ico',

  // SEO metadata
  headTags: [
    {
      tagName: 'meta',
      attributes: {
        name: 'description',
        content:
          'gummyworm - A Ruby gem that transforms images into beautiful ASCII art with color support, multiple export formats, and customizable palettes.',
      },
    },
    {
      tagName: 'meta',
      attributes: {
        name: 'keywords',
        content:
          'ASCII art, image converter, Ruby gem, CLI tool, terminal art, ANSI color, text graphics',
      },
    },
    {
      tagName: 'meta',
      attributes: {
        property: 'og:type',
        content: 'website',
      },
    },
    {
      tagName: 'meta',
      attributes: {
        property: 'og:title',
        content: 'gummyworm - ASCII Art Generator',
      },
    },
    {
      tagName: 'meta',
      attributes: {
        property: 'og:description',
        content:
          'Transform images into glorious ASCII art with color support and multiple export formats.',
      },
    },
    {
      tagName: 'meta',
      attributes: {
        name: 'twitter:card',
        content: 'summary',
      },
    },
  ],

  future: {
    v4: true,
  },

  url: 'https://oddurs.github.io',
  baseUrl: '/gummyworm/',

  organizationName: 'oddurs',
  projectName: 'gummyworm',

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  themes: [
    [
      '@easyops-cn/docusaurus-search-local',
      {
        hashed: true,
        docsRouteBasePath: '/',
        indexBlog: false,
        highlightSearchTermsOnTargetPage: true,
      },
    ],
  ],

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          editUrl: 'https://github.com/oddurs/gummyworm/tree/main/docs/',
          routeBasePath: '/', // Docs at root, no landing page
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      colorMode: {
        defaultMode: 'light',
        respectPrefersColorScheme: true,
      },
      navbar: {
        title: 'gummyworm',
        items: [
          {
            href: 'https://github.com/oddurs/gummyworm',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Getting Started',
                to: '/',
              },
              {
                label: 'CLI Reference',
                to: '/cli-reference',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/oddurs/gummyworm',
              },
              {
                label: 'Releases',
                href: 'https://github.com/oddurs/gummyworm/releases',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} gummyworm. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ['bash', 'ruby', 'json', 'yaml', 'docker'],
      },
    }),
};

export default config;

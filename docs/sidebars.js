/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docs: [
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: ['intro', 'installation', 'examples'],
    },
    {
      type: 'category',
      label: 'Reference',
      items: ['cli-reference', 'configuration', 'palettes', 'export-formats'],
    },
    {
      type: 'category',
      label: 'Guides',
      items: ['troubleshooting', 'architecture', 'testing'],
    },
    {
      type: 'category',
      label: 'Distribution',
      items: ['homebrew', 'shell-completions'],
    },
  ],
};

export default sidebars;

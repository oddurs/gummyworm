import React from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import '../css/landing.css';

// ASCII art logo
const asciiLogo = `
   ██████╗ ██╗   ██╗███╗   ███╗███╗   ███╗██╗   ██╗██╗    ██╗ ██████╗ ██████╗ ███╗   ███╗
  ██╔════╝ ██║   ██║████╗ ████║████╗ ████║╚██╗ ██╔╝██║    ██║██╔═══██╗██╔══██╗████╗ ████║
  ██║  ███╗██║   ██║██╔████╔██║██╔████╔██║ ╚████╔╝ ██║ █╗ ██║██║   ██║██████╔╝██╔████╔██║
  ██║   ██║██║   ██║██║╚██╔╝██║██║╚██╔╝██║  ╚██╔╝  ██║███╗██║██║   ██║██╔══██╗██║╚██╔╝██║
  ╚██████╔╝╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║ ╚═╝ ██║
   ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝`;

const asciiTagline = `·:·:· Transform images into glorious ASCII art ·:·:·`;

const features = [
  {
    icon: '🎨',
    title: '12 Built-in Palettes',
    description:
      'Choose from ASCII, blocks, dots, braille, emoji, and more. Create custom palettes for unique effects.',
  },
  {
    icon: '🌈',
    title: 'Full Color Support',
    description:
      '256-color and truecolor (16M) ANSI output. Bring your ASCII art to life with vibrant colors.',
  },
  {
    icon: '📤',
    title: 'Multiple Export Formats',
    description: 'Export to HTML, SVG, or PNG. Perfect for sharing on the web or printing.',
  },
  {
    icon: '⚡',
    title: 'Fast & Lightweight',
    description:
      'Pure Bash with no external dependencies beyond ImageMagick. Runs anywhere with a Unix shell.',
  },
  {
    icon: '🔧',
    title: 'Highly Configurable',
    description:
      'Control dimensions, aspect ratio, brightness, contrast, and more via CLI or config file.',
  },
  {
    icon: '🎬',
    title: 'Animated GIF Support',
    description:
      'Process and play animated GIFs in your terminal, or export them as ASCII art animations.',
  },
];

function Hero() {
  return (
    <header className="hero">
      <div className="container">
        <div className="ascii-showcase">
          <pre className="ascii-logo">{asciiLogo}</pre>
          <pre className="ascii-tagline">{asciiTagline}</pre>
        </div>

        <div className="hero__buttons">
          <Link className="hero__button hero__button--primary" to="/docs/intro">
            Get Started
          </Link>
          <Link
            className="hero__button hero__button--secondary"
            href="https://github.com/oddurs/gummyworm"
          >
            View on GitHub
          </Link>
        </div>
      </div>
    </header>
  );
}

function Features() {
  return (
    <section className="features">
      <div className="features__container">
        <h2 className="features__title">Why gummyworm?</h2>
        <div className="features__grid">
          {features.map((feature, idx) => (
            <div key={idx} className="feature">
              <div className="feature__icon">{feature.icon}</div>
              <h3 className="feature__title">{feature.title}</h3>
              <p className="feature__description">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function CodeExample() {
  return (
    <section className="code-example">
      <div className="code-example__container">
        <h2 className="code-example__title">Simple to Use</h2>
        <div className="code-example__block">
          <div className="code-example__header">
            <span className="code-example__dot code-example__dot--red"></span>
            <span className="code-example__dot code-example__dot--yellow"></span>
            <span className="code-example__dot code-example__dot--green"></span>
          </div>
          <div className="code-example__content">
            <pre>
              <code>
                <span className="code-example__prompt">$ </span>
                <span className="code-example__command">gummyworm image.png -c -w 80</span>
                {'\n\n'}
                <span style={{ color: '#888' }}># Convert with color, 80 chars wide</span>
                {'\n\n'}
                <span className="code-example__prompt">$ </span>
                <span className="code-example__command">
                  gummyworm photo.jpg -p braille --html output.html
                </span>
                {'\n\n'}
                <span style={{ color: '#888' }}># Export as HTML with braille palette</span>
                {'\n\n'}
                <span className="code-example__prompt">$ </span>
                <span className="code-example__command">gummyworm avatar.png -p emoji -w 40</span>
                {'\n\n'}
                <span style={{ color: '#888' }}># Create emoji art</span>
              </code>
            </pre>
          </div>
        </div>
      </div>
    </section>
  );
}

function Install() {
  return (
    <section className="install">
      <div className="container">
        <h2 className="install__title">Quick Install</h2>
        <div className="install__options">
          <div className="install__option">
            <code>gem install gummyworm</code>
          </div>
          <div className="install__option">
            <code>brew install oddurs/tap/gummyworm</code>
          </div>
        </div>
      </div>
    </section>
  );
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout title={`${siteConfig.title} - ASCII Art Generator`} description={siteConfig.tagline}>
      <Hero />
      <main>
        <Features />
        <CodeExample />
        <Install />
      </main>
    </Layout>
  );
}

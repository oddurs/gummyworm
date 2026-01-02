# typed: false
# frozen_string_literal: true

class Gummyworm < Formula
  desc "gummyworm - Transform images into glorious ASCII art"
  homepage "https://github.com/oddurs/gummyworm"
  url "https://github.com/oddurs/gummyworm/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/oddurs/gummyworm.git", branch: "main"

  depends_on "imagemagick"

  def install
    # Install the main executable
    bin.install "bin/gummyworm"

    # Install library files
    (libexec/"lib").install Dir["lib/*.sh"]

    # Install palettes
    (libexec/"palettes").install Dir["palettes/*.palette"]

    # Rewrite the main script to find lib files in the correct location
    inreplace bin/"gummyworm" do |s|
      s.gsub! 'GUMMYWORM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"',
              "GUMMYWORM_ROOT=\"#{libexec}\""
      s.gsub! 'GUMMYWORM_ROOT="$SCRIPT_DIR"',
              "GUMMYWORM_ROOT=\"#{libexec}\""
    end
  end

  test do
    # Create a simple test image
    system "convert", "-size", "10x10", "xc:white", "test.png"
    
    # Run gummyworm on it
    output = shell_output("#{bin}/gummyworm -q -w 10 test.png")
    assert_match(/[^\s]/, output)
  end
end

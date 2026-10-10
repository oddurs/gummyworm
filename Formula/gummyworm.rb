# typed: false
# frozen_string_literal: true

class Gummyworm < Formula
  desc "gummyworm - Transform images into glorious ASCII art"
  homepage "https://github.com/oddurs/gummyworm"
  url "https://github.com/oddurs/gummyworm/archive/refs/tags/v2.4.0.tar.gz"
  sha256 "68c4ae1d59d805fa790db281c34e76f3b434c6c6a481d1f1550b1c005cd146eb"
  version "2.4.0"
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

    # Install shell completions
    bash_completion.install "completions/gummyworm.bash" => "gummyworm"
    zsh_completion.install "completions/_gummyworm"

    # Set GUMMYWORM_ROOT to libexec for Homebrew installation
    inreplace bin/"gummyworm",
              "#!/usr/bin/env bash",
              "#!/usr/bin/env bash\nGUMMYWORM_ROOT=\"#{libexec}\""
  end

  test do
    # Create a simple test image
    system "convert", "-size", "10x10", "xc:white", "test.png"
    
    # Run gummyworm on it
    output = shell_output("#{bin}/gummyworm -q -w 10 test.png")
    assert_match(/[^\s]/, output)
  end
end

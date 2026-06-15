class Holdline < Formula
  desc "Freeze merges across your GitHub org from the terminal"
  homepage "https://github.com/lesssoftware/releases"
  # tag_prefix: holdline-v
  version "0.1.0"
  license "MIT"

  # Apple Silicon only on macOS (no Intel build shipped).
  depends_on arch: :arm64 if OS.mac?

  on_macos do
    url "https://github.com/lesssoftware/releases/releases/download/holdline-v0.1.0/holdline-v0.1.0-macos-aarch64.tar.gz"
    sha256 "a59490eef5404ad3eb19b42890cb20ea8a1c2c15dceede95b53466d473ed5ce8"
  end

  on_linux do
    url "https://github.com/lesssoftware/releases/releases/download/holdline-v0.1.0/holdline-v0.1.0-linux-x86_64.tar.gz"
    sha256 "a7ab0dcf36527080b18641fa40fe59bd6da18ded7e66f4a002f9a1ee9346dcdd"
  end

  def install
    bin.install "holdline"

    generate_completions_from_executable(bin/"holdline", "completions")
  end

  test do
    assert_match "holdline v", shell_output("#{bin}/holdline --version")
  end
end

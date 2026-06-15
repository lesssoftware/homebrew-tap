class Changefinch < Formula
  desc "Publish changelog entries from the terminal"
  homepage "https://github.com/lesssoftware/releases"
  # tag_prefix: changefinch-v
  version "0.1.0"
  license "MIT"

  # Apple Silicon only on macOS (no Intel build shipped).
  depends_on arch: :arm64 if OS.mac?

  on_macos do
    url "https://github.com/lesssoftware/releases/releases/download/changefinch-v0.1.0/changefinch-v0.1.0-macos-aarch64.tar.gz"
    sha256 "b22ce4c6159319da14eb558cdf5d74b48c6dd8b82d905207445a06959ca54270"
  end

  on_linux do
    url "https://github.com/lesssoftware/releases/releases/download/changefinch-v0.1.0/changefinch-v0.1.0-linux-x86_64.tar.gz"
    sha256 "8faa96dc9a64dd671a52eb916c384fa63474110eced6f3d57358201235be70b0"
  end

  def install
    bin.install "changefinch"

    generate_completions_from_executable(bin/"changefinch", "completions")
  end

  test do
    assert_match "changefinch v", shell_output("#{bin}/changefinch --version")
  end
end

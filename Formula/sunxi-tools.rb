class SunxiTools < Formula
  desc "Tools for Allwinner SoCs, including the sunxi-fel USB boot tool"
  homepage "https://linux-sunxi.org/Sunxi-tools"
  # The last release, v1.4.2, is from 2016 and knows only 11 SoCs; master
  # supports many more (H6, H616, F1C100s, ...), so package a pinned commit.
  url "https://github.com/linux-sunxi/sunxi-tools/archive/34dfa20f8284273085666436e4cac09af19646c8.tar.gz"
  version "1.4.2-unstable-2026-11-05"
  sha256 "3430c4e3602aca30e73dddb438a4b15907efad73518ce85d7dfb2a98e40b7dc6"
  license "GPL-2.0-or-later"
  head "https://github.com/linux-sunxi/sunxi-tools.git", branch: "master"

  livecheck do
    skip "Tracks an unreleased commit"
  end

  depends_on "pkgconf" => :build
  depends_on "dtc"
  depends_on "libusb"

  uses_from_macos "zlib"

  def install
    system "make", "tools", "CC=#{ENV.cc}"
    system "make", "install-tools", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"board.fex").write <<~EOS
      [product]
      version = "100"
      machine = "homebrew"

      [target]
      boot_clock = 1008
    EOS

    system bin/"fex2bin", "board.fex", "board.bin"
    assert_path_exists testpath/"board.bin"
    assert_match "machine = \"homebrew\"", shell_output("#{bin}/bin2fex board.bin")

    # No board is attached, so sunxi-fel can only report that.
    assert_match "FEL device not found", shell_output("#{bin}/sunxi-fel ver 2>&1", 1)
  end
end

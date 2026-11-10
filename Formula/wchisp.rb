class Wchisp < Formula
  desc "Command-line ISP flasher for WCH CH32/CH5x microcontrollers"
  homepage "https://github.com/ch32-rs/wchisp"
  url "https://github.com/ch32-rs/wchisp/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "bd6a20b5976a19a56f3fea6694d964edbba99a394fc1513a6cbf8d9040a04538"
  license "GPL-2.0-only"
  head "https://github.com/ch32-rs/wchisp.git", branch: "main"

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "libusb"

  def install
    # The default feature vendors its own libusb; link Homebrew's instead.
    system "cargo", "install", "--no-default-features", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wchisp --version")
    # No chip is attached, so wchisp can only report that.
    assert_match "No WCH ISP USB device found", shell_output("#{bin}/wchisp info 2>&1", 1)
  end
end

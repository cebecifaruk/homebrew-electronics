class Ecpprog < Formula
  desc "Programmer for Lattice ECP5 and NX FPGAs over FTDI JTAG"
  homepage "https://github.com/gregdavill/ecpprog"
  # Upstream has never tagged a release.
  url "https://github.com/gregdavill/ecpprog/archive/1931c3e121f682536a9d80ca1ce1b651c11aef76.tar.gz"
  version "0-unstable-2024-11-07"
  sha256 "23664188884c04eca5d799896a5e0cc23fd944713fbf7e9c9f12998e8d192d30"
  license "ISC"
  head "https://github.com/gregdavill/ecpprog.git", branch: "main"

  livecheck do
    skip "No tagged releases"
  end

  depends_on "pkgconf" => :build
  depends_on "libftdi"

  def install
    cd "ecpprog" do
      system "make", "CC=#{ENV.cc}", "PREFIX=#{prefix}"
      system "make", "install", "PREFIX=#{prefix}"
    end
  end

  test do
    # No programmer is attached, so ecpprog can only report that.
    assert_match "Can't find", shell_output("#{bin}/ecpprog -t 2>&1", 2)
  end
end

class Qrouter < Formula
  desc "Detail maze router for ASIC layouts"
  homepage "https://opencircuitdesign.com/qrouter/"
  url "https://github.com/RTimothyEdwards/qrouter/archive/refs/tags/1.4.90.tar.gz"
  sha256 "bcb43b2c19b67fb0175b5fb0a85b892d132a6936f0997154343bc4bb30a0caf1"
  license "GPL-2.0-only"
  head "https://github.com/RTimothyEdwards/qrouter.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cebecifaruk/electronics/tcl-tk-x11"
  depends_on "libx11"

  def install
    # Current linkers reject the obsolete -noprebind flag, and Homebrew
    # rejects flat-namespace libraries; dynamic_lookup still resolves the
    # Tcl/Tk symbols from the host interpreter at load time.
    inreplace "configure", "-flat_namespace -undefined suppress -noprebind", "-undefined dynamic_lookup"

    # qrouter's GUI runs inside wish, so it needs the X11 Tk rather than the
    # Aqua Tk from tcl-tk/tcl-tk@8.
    tcltk_lib = formula_opt_lib("tcl-tk-x11")
    system "./configure", "--prefix=#{prefix}",
                          "--with-tcl=#{tcltk_lib}",
                          "--with-tk=#{tcltk_lib}",
                          "--x-includes=#{formula_opt_include("libx11")}",
                          "--x-libraries=#{formula_opt_lib("libx11")}"
    system "make"
    system "make", "install"
    pkgshare.install "lib/osu035_stdcells.lef", "lib/route.cfg"
  end

  def caveats
    <<~EOS
      qrouter's GUI is an X11 application; install XQuartz to use it:
        brew install --cask xquartz
      Batch routing runs without a display, for example:
        qrouter -nog -c route.cfg design
    EOS
  end

  test do
    cp pkgshare/"osu035_stdcells.lef", testpath
    (testpath/"route.cfg").write (pkgshare/"route.cfg").read.sub(/^lef .*$/, "lef osu035_stdcells.lef")

    # -i reads the technology and writes route pitches, without a display.
    system bin/"qrouter", "-i", "info.txt", "-c", "route.cfg"
    info = (testpath/"info.txt").read
    assert_match "qrouter #{version}", info
    assert_match(/^metal2 1\.6 .* vertical/, info)
  end
end

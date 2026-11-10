class Irsim < Formula
  desc "Switch-level digital circuit simulator"
  homepage "https://opencircuitdesign.com/irsim/"
  url "https://github.com/RTimothyEdwards/irsim/archive/refs/tags/9.7.121.tar.gz"
  sha256 "b1b2149f662637a431ab39f4be93a11013df0eff5b4df21b17e9b9dd5fd01692"
  license "GPL-2.0-only"
  head "https://github.com/RTimothyEdwards/irsim.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cebecifaruk/electronics/tcl-tk-x11"
  depends_on "libx11"

  def install
    # Current linkers reject the obsolete -noprebind flag, and Homebrew
    # rejects flat-namespace libraries; dynamic_lookup still resolves the
    # Tcl/Tk symbols from the host wish at load time.
    inreplace "scripts/configure", "-flat_namespace -undefined suppress -noprebind", "-undefined dynamic_lookup"

    # irsim runs inside wish, so it needs the X11 Tk rather than the Aqua Tk
    # from tcl-tk/tcl-tk@8. Its configure wrapper overrides CFLAGS from the
    # environment, so pass them as an argument; several sources omit
    # <string.h>, which current clang rejects.
    tcltk_lib = formula_opt_lib("tcl-tk-x11")
    system "./configure", "--prefix=#{prefix}",
                          "--with-tcl=#{tcltk_lib}",
                          "--with-tk=#{tcltk_lib}",
                          "--x-includes=#{formula_opt_include("libx11")}",
                          "--x-libraries=#{formula_opt_lib("libx11")}",
                          "CFLAGS=-O2 -Wno-implicit-function-declaration"
    system "make"
    system "make", "install"
  end

  def caveats
    <<~EOS
      irsim is an X11 application. To use it, install XQuartz, then log out
      and back in so that DISPLAY is set:
        brew install --cask xquartz
    EOS
  end

  test do
    assert_path_exists lib/"irsim/prm/scmos100.prm"

    if OS.mac?
      assert_match "#{formula_opt_bin("tcl-tk-x11")}/wish", (bin/"irsim").read
      assert_match "libX11", shell_output("otool -L #{lib}/irsim/tcl/tclirsim.dylib")
    end

    # irsim always starts Tk; without a display, the X11 Tk says so.
    output = pipe_output("env -u DISPLAY #{bin}/irsim -noconsole 2>&1", "")
    assert_match "no display name", output
  end
end

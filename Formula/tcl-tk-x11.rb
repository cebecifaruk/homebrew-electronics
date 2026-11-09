class TclTkX11 < Formula
  desc "Tcl/Tk 8.6 with Tk drawing through X11 instead of Aqua"
  homepage "https://www.tcl-lang.org"
  url "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.18/tcl8.6.18-src.tar.gz"
  sha256 "14f9af32b1767ff718477a8f974ad03c34341097e6b43f4ce54644ee974e268e"
  license "TCL"

  livecheck do
    url :stable
    regex(%r{url=.*?/(?:tcl|tk).?v?(8(?:\.\d+)+)[._-]src\.t}i)
  end

  # Same file names as homebrew/core's tcl-tk@8 (tclsh8.6, wish8.6, libtcl8.6).
  keg_only "it conflicts with `tcl-tk@8`"

  depends_on "pkgconf" => :build
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "libx11"
  depends_on "libxft"

  uses_from_macos "zlib"

  resource "tk" do
    url "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.18/tk8.6.18-src.tar.gz"
    sha256 "95cd528a80f5e4bdb557af9b14a7197d6860793a3894e25e7c9fad2ed05d4c3c"

    livecheck do
      formula :parent
    end
  end

  def install
    odie "tk resource needs to be updated" if version != resource("tk").version

    args = %W[
      --prefix=#{prefix}
      --mandir=#{man}
      --enable-man-suffix
      --enable-threads
      --enable-64bit
    ]

    cd "unix" do
      system "./configure", *args
      system "make"
      system "make", "install"
      system "make", "install-private-headers"
    end

    # Tk's configure takes Tcl's header paths from the Tcl source tree, so
    # build it here, while that tree still exists. Otherwise it falls back to
    # the SDK's Tcl 8.5 headers and fails.
    resource("tk").stage do
      cd "unix" do
        system "./configure", *args,
                              "--with-tcl=#{lib}",
                              "--enable-aqua=no",
                              "--with-x",
                              "--enable-xft",
                              "--disable-xss",
                              "--x-includes=#{formula_opt_include("libx11")}",
                              "--x-libraries=#{formula_opt_lib("libx11")}"
        # Tk appends the X11 library directory to its own install name,
        # which produces a broken path like `.../lib:/opt/X11/lib/libtk8.6.dylib`.
        inreplace "Makefile", /^LIB_RUNTIME_DIR\s*=.*$/, "LIB_RUNTIME_DIR = $(libdir)"
        system "make"
        system "make", "install"
        system "make", "install-private-headers"
      end
    end

    bin.install_symlink "tclsh#{version.major_minor}" => "tclsh"
    bin.install_symlink "wish#{version.major_minor}" => "wish"

    # Dependents read paths such as the wish location from these files. Point
    # them at opt_prefix so that they keep working after this formula upgrades.
    inreplace [lib/"tclConfig.sh", lib/"tkConfig.sh"], prefix.to_s, opt_prefix.to_s
  end

  test do
    assert_equal "honk", pipe_output("#{bin}/tclsh", "puts honk\n").chomp
    assert_match "TK_VERSION='#{version.major_minor}'", (lib/"tkConfig.sh").read

    if OS.mac?
      tk_libs = shell_output("otool -L #{lib}/libtk#{version.major_minor}.dylib")
      assert_match "libX11", tk_libs
      assert_match "libXft", tk_libs
      refute_match "Cocoa", tk_libs
    end

    # Without an X server, an X11 Tk fails to find a display, whereas an Aqua
    # Tk would open a window. wish exits 0 either way, so check the message.
    output = pipe_output("env -u DISPLAY #{bin}/wish 2>&1", "")
    assert_match "no display name", output
  end
end

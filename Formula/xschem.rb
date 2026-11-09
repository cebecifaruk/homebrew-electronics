class Xschem < Formula
  desc "Schematic capture and netlisting EDA tool"
  homepage "https://xschem.sourceforge.io/stefan/index.html"
  url "https://github.com/StefanSchippers/xschem/archive/refs/tags/3.4.7.tar.gz"
  sha256 "8f6c7165c38f528b6cbae8f9fae72cde3b765652df90597011a5f7b5e7fdb273"
  license "GPL-2.0-or-later"
  head "https://github.com/StefanSchippers/xschem.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "pkgconf" => :build
  depends_on "cairo"
  depends_on "jpeg-turbo"
  depends_on "libx11"
  depends_on "libxcb"
  depends_on "libxft"
  depends_on "libxpm"
  depends_on "libxrender"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "zlib"

  # xschem draws with Xlib, so it needs a Tk that also draws with X11. The
  # tcl-tk formulae build Tk for Aqua on macOS, and xschem hangs or crashes
  # with that, so build a private X11 Tcl/Tk 8.6 in libexec.
  resource "tcl" do
    url "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.18/tcl8.6.18-src.tar.gz"
    sha256 "14f9af32b1767ff718477a8f974ad03c34341097e6b43f4ce54644ee974e268e"
  end

  resource "tk" do
    url "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.18/tk8.6.18-src.tar.gz"
    sha256 "95cd528a80f5e4bdb557af9b14a7197d6860793a3894e25e7c9fad2ed05d4c3c"
  end

  def install
    tcltk = libexec/"tcltk"
    tcltk_args = %W[
      --prefix=#{tcltk}
      --enable-threads
      --enable-64bit
    ]

    resource("tcl").stage do
      cd "unix" do
        system "./configure", *tcltk_args
        system "make"
        system "make", "install"
      end

      # Tk's configure takes Tcl's header paths from the Tcl source tree, so
      # build Tk while that tree is still staged. Otherwise it falls back to
      # the SDK's Tcl 8.5 headers and fails.
      resource("tk").stage do
        cd "unix" do
          system "./configure", *tcltk_args,
                                "--with-tcl=#{tcltk}/lib",
                                "--disable-aqua",
                                "--with-x",
                                "--enable-xft",
                                "--x-includes=#{formula_opt_include("libx11")}",
                                "--x-libraries=#{formula_opt_lib("libx11")}"
          # Tk appends the X11 library directory to its own install name,
          # which produces a broken path like `.../lib:/opt/X11/lib/libtk8.6.dylib`.
          inreplace "Makefile", /^LIB_RUNTIME_DIR\s*=.*$/, "LIB_RUNTIME_DIR = $(libdir)"
          system "make"
          system "make", "install"
        end
      end
    end

    # xschem's configure finds Tcl/Tk through tclsh on PATH.
    ENV.prepend_path "PATH", tcltk/"bin"
    system "./configure", "--prefix=#{prefix}",
                          "/arg/tk-version=8.6",
                          "--prefix/libs/script/tcl=#{tcltk}",
                          "--prefix/libs/script/tk=#{tcltk}"
    system "make"
    system "make", "install"
  end

  def caveats
    <<~EOS
      xschem is an X11 application. To use its GUI, install XQuartz, then log
      out and back in so that DISPLAY is set:
        brew install --cask xquartz

      Its default terminal is xterm, which XQuartz provides.
    EOS
  end

  test do
    assert_match "XSCHEM V#{version}", shell_output("#{bin}/xschem --version")

    if OS.mac?
      tk_libs = shell_output("otool -L #{libexec}/tcltk/lib/libtk8.6.dylib")
      assert_match "libX11", tk_libs
      refute_match "Cocoa", tk_libs
    end

    (testpath/"divider.sch").write <<~EOS
      v {xschem version=#{version} file_version=1.2}
      G {}
      K {}
      V {}
      S {}
      E {}
      C {res.sym} 0 0 0 0 {name=R1 value=1k}
      C {res.sym} 0 100 0 0 {name=R2 value=2k}
      N 0 30 0 70 {lab=MID}
      C {ipin.sym} -60 -30 0 0 {name=p1 lab=IN}
      C {opin.sym} 60 50 0 0 {name=p2 lab=MID}
      C {gnd.sym} 0 130 0 0 {name=l1 lab=GND}
      N -60 -30 0 -30 {lab=IN}
      N 0 50 60 50 {lab=MID}
    EOS

    ENV["HOME"] = testpath
    system bin/"xschem", "--no_x", "--quit", "--spice", "--netlist",
           "--netlist_path", testpath, testpath/"divider.sch"
    netlist = (testpath/"divider.spice").read
    assert_match(/^R1 IN MID 1k/, netlist)
    assert_match(/^R2 MID GND 2k/, netlist)
    refute_match "IS MISSING", netlist
  end
end

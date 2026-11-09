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
  depends_on "cebecifaruk/electronics/tcl-tk-x11"
  depends_on "jpeg-turbo"
  depends_on "libx11"
  depends_on "libxcb"
  depends_on "libxpm"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build

  def install
    # xschem draws with Xlib, so it needs a Tk that also draws with X11; it
    # hangs or crashes with the Aqua Tk from tcl-tk/tcl-tk@8. Its configure
    # finds Tcl/Tk through tclsh on PATH.
    tcltk = formula_opt_prefix("tcl-tk-x11")
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
      tcltk = formula_opt_lib("tcl-tk-x11")
      assert_match "#{tcltk}/libtk8.6.dylib", shell_output("otool -L #{bin}/xschem")
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

class Magic < Formula
  desc "VLSI layout editor"
  homepage "https://opencircuitdesign.com/magic/"
  url "https://github.com/RTimothyEdwards/magic/archive/refs/tags/8.3.696.tar.gz"
  sha256 "637bfd71fff8a049d2ff5c99399e6a38c67852c8920e2906fa641aa1cfc2834e"
  license "HPND-UC"
  head "https://github.com/RTimothyEdwards/magic.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cairo"
  depends_on "cebecifaruk/electronics/tcl-tk-x11"
  depends_on "libx11"
  depends_on "libxext"

  uses_from_macos "python" => :build
  uses_from_macos "zlib"

  def install
    # magic runs inside wish and draws with Xlib or cairo, so it needs a Tk
    # that also draws with X11 rather than the Aqua Tk from tcl-tk/tcl-tk@8.
    tcltk_lib = formula_opt_lib("tcl-tk-x11")
    system "./configure", "--prefix=#{prefix}",
                          "--with-tcl=#{tcltk_lib}",
                          "--with-tk=#{tcltk_lib}",
                          "--with-cairo=#{formula_opt_include("cairo")}",
                          "--with-opengl=no",
                          "--disable-magic-builddate",
                          "--x-includes=#{formula_opt_include("libx11")}",
                          "--x-libraries=#{formula_opt_lib("libx11")}",
                          "CFLAGS=-O2"
    system "make", "prepare"
    system "make"
    system "make", "install"
  end

  def caveats
    <<~EOS
      magic is an X11 application. To use its GUI, install XQuartz, then log
      out and back in so that DISPLAY is set:
        brew install --cask xquartz

      For scripting without a display, run:
        magic -dnull -noconsole
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/magic --version")

    (testpath/"draw.tcl").write <<~TCL
      tech load scmos
      load square
      box 0 0 10 10
      paint m1
      gds write square.gds
      quit -noprompt
    TCL

    system bin/"magic", "-dnull", "-noconsole", testpath/"draw.tcl"
    assert_path_exists testpath/"square.gds"
    # A GDSII stream starts with a HEADER record: length 6, type 0x0002.
    assert_equal "\x00\x06\x00\x02".b, (testpath/"square.gds").binread(4)
  end
end

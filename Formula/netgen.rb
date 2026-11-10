class Netgen < Formula
  desc "Netlist comparison (LVS) and netlist management tool"
  homepage "https://opencircuitdesign.com/netgen/"
  url "https://github.com/RTimothyEdwards/netgen/archive/refs/tags/1.5.328.tar.gz"
  sha256 "be30dde15f3f3b3632d35a334d2976abb27d72403b0f93a03ea97285f777eaea"
  license "GPL-1.0-or-later"
  head "https://github.com/RTimothyEdwards/netgen.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cebecifaruk/electronics/tcl-tk-x11"
  depends_on "libx11"

  def install
    # netgen runs inside wish, so it needs the X11 Tk rather than the Aqua Tk
    # from tcl-tk/tcl-tk@8.
    tcltk_lib = formula_opt_lib("tcl-tk-x11")
    system "./configure", "--prefix=#{prefix}",
                          "--with-tcl=#{tcltk_lib}",
                          "--with-tk=#{tcltk_lib}",
                          "--x-includes=#{formula_opt_include("libx11")}",
                          "--x-libraries=#{formula_opt_lib("libx11")}"
    system "make"
    system "make", "install"
  end

  def caveats
    <<~EOS
      netgen's console is an X11 application. To use it, install XQuartz,
      then log out and back in so that DISPLAY is set:
        brew install --cask xquartz

      Batch LVS runs without a display, for example:
        netgen -batch lvs "layout.spice top" "schematic.spice top" setup.tcl
    EOS
  end

  test do
    (testpath/"a.spice").write <<~EOS
      .subckt divider in mid gnd
      R1 in mid 1k
      R2 mid gnd 2k
      .ends
    EOS
    # Same circuit, with the devices listed in the other order.
    (testpath/"b.spice").write <<~EOS
      .subckt divider in mid gnd
      R2 mid gnd 2k
      R1 in mid 1k
      .ends
    EOS
    (testpath/"setup.tcl").write ""

    system bin/"netgen", "-batch", "lvs", "a.spice divider", "b.spice divider",
           "setup.tcl", "comp.out"
    assert_match "Netlists match uniquely", (testpath/"comp.out").read
  end
end

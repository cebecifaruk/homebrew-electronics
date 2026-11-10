class Nextpnr < Formula
  desc "Portable FPGA place and route tool"
  homepage "https://github.com/YosysHQ/nextpnr"
  url "https://github.com/YosysHQ/nextpnr/archive/refs/tags/nextpnr-0.11.1.tar.gz"
  sha256 "2af682d94abf3f3e116f2fad36dc7db314fa93bfbb185e63619f2ec4f5fe40dc"
  license "ISC"
  head "https://github.com/YosysHQ/nextpnr.git", branch: "main"

  livecheck do
    url :stable
    regex(/^nextpnr[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cmake" => :build
  depends_on "yosys" => :test
  depends_on "boost"
  depends_on "cebecifaruk/electronics/apycula"
  depends_on "cebecifaruk/electronics/prjoxide"
  depends_on "cebecifaruk/electronics/prjtrellis-latest"
  depends_on "eigen"
  depends_on "icestorm"
  depends_on "python@3.15"

  conflicts_with "nextpnr-ice40", because: "both install `nextpnr-ice40`"

  def install
    # The chip databases are generated at build time from these projects:
    # icestorm (iCE40), prjtrellis (ECP5, MachXO2), prjoxide (Nexus) and
    # apycula (Gowin, through the Himbaechel architecture). The prjtrellis
    # release in homebrew/core lacks the MachXO2/MachXO3 timing data, so use
    # the newer keg-only build from this tap.
    args = %W[
      -DARCH=generic;ice40;ecp5;machxo2;nexus;himbaechel
      -DHIMBAECHEL_UARCH=gowin
      -DPython3_EXECUTABLE=#{formula_opt_bin("python@3.15")}/python3.15
      -DICESTORM_INSTALL_PREFIX=#{formula_opt_prefix("icestorm")}
      -DICEBOX_DATADIR=#{Formula["icestorm"].opt_pkgshare}/chipdb
      -DTRELLIS_INSTALL_PREFIX=#{formula_opt_prefix("prjtrellis-latest")}
      -DOXIDE_INSTALL_PREFIX=#{formula_opt_prefix("prjoxide")}
      -DAPYCULA_INSTALL_PREFIX=#{formula_opt_libexec("apycula")}
      -DEigen3_DIR=#{formula_opt_prefix("eigen")}/share/eigen3/cmake
      -DUSE_IPO=OFF
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    pkgshare.install "ice40/examples"
  end

  test do
    yosys = formula_opt_bin("yosys")/"yosys"

    # iCE40: the upstream blinky example, all the way to a bitstream.
    cp_r (pkgshare/"examples/blinky").children, testpath
    system yosys, "-q", "blinky.ys"
    system bin/"nextpnr-ice40", "--hx1k", "--package", "tq144", "--json", "blinky.json",
                                "--pcf", "blinky.pcf", "--asc", "blinky.asc", "--quiet"
    system formula_opt_bin("icestorm")/"icepack", "blinky.asc", "blinky.bin"
    assert_path_exists testpath/"blinky.bin"

    # The other architectures: place and route a small LFSR. (A counter would
    # also work, except that nextpnr-nexus 0.11.1 fails to pack its carry chain.)
    (testpath/"lfsr.v").write <<~VERILOG
      module top(input clk, output [3:0] led);
        reg [15:0] lfsr = 16'h1;
        always @(posedge clk) lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        assign led = lfsr[15:12];
      endmodule
    VERILOG

    system yosys, "-q", "-p", "synth_ecp5 -top top -json ecp5.json", "lfsr.v"
    system bin/"nextpnr-ecp5", "--25k", "--json", "ecp5.json", "--textcfg", "ecp5.config", "--quiet"
    system formula_opt_bin("prjtrellis-latest")/"ecppack", "ecp5.config", "ecp5.bit"
    assert_path_exists testpath/"ecp5.bit"

    # Nexus and Gowin refuse unconstrained IO, so pin the ports.
    (testpath/"nexus.pdc").write <<~EOS
      ldc_set_location -site {L13} [get_ports clk]
      ldc_set_location -site {E17} [get_ports {led[0]}]
      ldc_set_location -site {F13} [get_ports {led[1]}]
      ldc_set_location -site {G13} [get_ports {led[2]}]
      ldc_set_location -site {F14} [get_ports {led[3]}]
    EOS
    system yosys, "-q", "-p", "synth_nexus -top top -json nexus.json", "lfsr.v"
    system bin/"nextpnr-nexus", "--device", "LIFCL-40-9BG400CES", "--pdc", "nexus.pdc",
                                "--json", "nexus.json", "--fasm", "nexus.fasm", "--quiet"
    system formula_opt_bin("prjoxide")/"prjoxide", "pack", "nexus.fasm", "nexus.bit"
    assert_path_exists testpath/"nexus.bit"

    (testpath/"gowin.cst").write <<~EOS
      IO_LOC "clk" 52;
      IO_LOC "led[0]" 10;
      IO_LOC "led[1]" 11;
      IO_LOC "led[2]" 13;
      IO_LOC "led[3]" 14;
    EOS
    system yosys, "-q", "-p", "synth_gowin -top top -json gowin.json", "lfsr.v"
    system bin/"nextpnr-himbaechel", "--device", "GW1NR-LV9QN88PC6/I5",
                                     "--vopt", "family=GW1N-9C", "--vopt", "cst=gowin.cst",
                                     "--json", "gowin.json", "--write", "gowin_pnr.json", "--quiet"
    system formula_opt_bin("apycula")/"gowin_pack", "-d", "GW1N-9C", "-o", "gowin.fs", "gowin_pnr.json"
    assert_path_exists testpath/"gowin.fs"

    system yosys, "-q", "-p", "synth_lattice -family xo2 -top top -json machxo2.json", "lfsr.v"
    system bin/"nextpnr-machxo2", "--device", "LCMXO2-1200HC-4SG32C", "--json", "machxo2.json",
                                  "--textcfg", "machxo2.config", "--quiet"
    assert_path_exists testpath/"machxo2.config"

    assert_match "nextpnr-generic", shell_output("#{bin}/nextpnr-generic --version 2>&1")
  end
end

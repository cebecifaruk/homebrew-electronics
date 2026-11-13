class Nextpnr < Formula
  desc "Portable FPGA place and route tool"
  homepage "https://github.com/YosysHQ/nextpnr"
  url "https://github.com/YosysHQ/nextpnr/archive/refs/tags/nextpnr-0.11.1.tar.gz"
  sha256 "2af682d94abf3f3e116f2fad36dc7db314fa93bfbb185e63619f2ec4f5fe40dc"
  # nextpnr itself is ISC. nextpnr-mistral statically links libmistral
  # (BSD-3-Clause), and the Xilinx chip databases are generated from the
  # CC0-licensed Project X-Ray data.
  license all_of: ["ISC", "BSD-3-Clause", "CC0-1.0"]
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
  depends_on "xz"

  conflicts_with "nextpnr-ice40", because: "both install `nextpnr-ice40`"

  # The release tarball lacks this git submodule: the site metadata that the
  # Xilinx chip database generator reads.
  resource "nextpnr-xilinx-meta" do
    url "https://github.com/gatecat/nextpnr-xilinx-meta/archive/491aefcc15be159efc8ad8bff2a1a4b93fe487fe.tar.gz"
    sha256 "a3558040446569c4a00fd1db57022f46a112946564a75d3e2cecb02d279340b2"
  end

  # Xilinx 7-series: the openXC7 fork of the Project X-Ray database, which
  # upstream CI builds against.
  resource "prjxray-db" do
    url "https://github.com/openXC7/prjxray-db/archive/refs/tags/0.9.1.tar.gz"
    sha256 "f1230c4ef1f01ea8fc3ee360ee235671a312f84eb470b4bd653f04ef39e2f098"
  end

  # Cologne Chip GateMate. The chip database generator of nextpnr 0.11.1
  # refuses any Project Peppercorn release other than v1.13.
  resource "prjpeppercorn" do
    url "https://github.com/YosysHQ/prjpeppercorn/archive/refs/tags/v1.13.tar.gz"
    sha256 "147880c5408f1a16372723b40bb904231acecd493ee3f90db2df35adb39be82c"
  end

  # NanoXplore NG-Ultra (Project Beyond). No releases are tagged.
  resource "prjbeyond-db" do
    url "https://github.com/YosysHQ-GmbH/prjbeyond-db/archive/f49f66be674d9857c657930353b867ba94bcbdd7.tar.gz"
    sha256 "606246e48d54b371a533084cb01f0cae879523db6f1c8d53b9162c6ecf5a0f39"
  end

  # Intel (Altera) Cyclone V: the Mistral library is compiled into
  # nextpnr-mistral. This is the revision that upstream CI pins.
  resource "mistral" do
    url "https://github.com/Ravenslofty/mistral/archive/ebfc0dd2cc7d6d2159b641a397c88554840e93c9.tar.gz"
    sha256 "59bee3f5c237908f32f88e99cc523b0d8aa50b69210f55a8fa1324ed644eec61"
  end

  def install
    python3 = formula_opt_bin("python@3.15")/"python3.15"

    # A head checkout already has the submodule.
    xilinx_meta = buildpath/"himbaechel/uarch/xilinx/meta"
    resource("nextpnr-xilinx-meta").stage(xilinx_meta) unless (xilinx_meta/"artix7").exist?

    # Stage the databases and Mistral outside the source tree's own
    # directories: nextpnr has a `mistral/` directory of its own.
    deps = buildpath/"deps"
    %w[prjxray-db prjpeppercorn prjbeyond-db mistral].each do |r|
      resource(r).stage(deps/r)
    end

    # nextpnr-mistral mixes int64_t with `long` literals in std::min/max, which
    # only compiles where int64_t is `long` (not macOS, where it is `long long`).
    inreplace "mistral/pack.cc" do |s|
      s.gsub! "std::max(12 - std::max(abits, dbits == 40 ? 8L : 9L), 0L)",
              "std::max<int64_t>(12 - std::max<int64_t>(abits, dbits == 40 ? 8 : 9), 0)"
      s.gsub! "std::min(dbits, 20L)", "std::min<int64_t>(dbits, 20)"
    end

    # Mistral's routing data generator copies 63 bytes for an error message
    # even near the end of its input buffer. The out-of-bounds read makes the
    # optimised build hang on the sx120f die, so clamp it to the buffer.
    inreplace deps/"mistral/generator/lines.cc" do |s|
      s.gsub! "memcpy(toto, p, 63);",
              "size_t tn = (size_t)(e - p) < 63 ? (size_t)(e - p) : 63; memcpy(toto, p, tn);"
      s.gsub! "toto[63] = 0;", "toto[tn] = 0;"
    end

    if OS.mac?
      # Mistral embeds its routing data with `ld -r -b binary`, which Apple's
      # linker does not support. Assemble the same `_binary_*` symbols with
      # `.incbin` instead.
      (deps/"mistral/bin2o.sh").write <<~'SH'
        #!/bin/sh
        # Usage: bin2o.sh <symbol stem> <input file> <output object>
        printf '\t.const_data\n\t.p2align 4\n\t.globl __binary_%s_start\n__binary_%s_start:\n\t.incbin "%s"\n\t.globl __binary_%s_end\n__binary_%s_end:\n' \
          "$1" "$1" "$2" "$1" "$1" > "$3.s"
        exec "${CC:-cc}" -c -o "$3" "$3.s"
      SH
      inreplace deps/"mistral/libmistral/CMakeLists.txt" do |s|
        s.gsub! "COMMAND ld -r -b binary -o cvd-${die}-r.o ${die}-r.bin",
                "COMMAND sh #{deps}/mistral/bin2o.sh ${die}_r_bin ${die}-r.bin cvd-${die}-r.o"
        s.gsub! "COMMAND ld -r -b binary -o cv-global.o global.bin",
                "COMMAND sh #{deps}/mistral/bin2o.sh global_bin global.bin cv-global.o"
      end
    end

    # Every architecture of nextpnr, and every Himbaechel microarchitecture:
    #   iCE40 (icestorm), ECP5 and MachXO2 (prjtrellis), Nexus (prjoxide),
    #   Cyclone V (Mistral), and through Himbaechel: Gowin (apycula), Xilinx
    #   7-series (prjxray-db), GateMate (prjpeppercorn), NG-Ultra (prjbeyond-db)
    #   and the example architecture.
    # The prjtrellis release in homebrew/core lacks the MachXO2/MachXO3 timing
    # data, so use the newer keg-only build from this tap. Mistral's CMake
    # files use the old FindPythonInterp module, hence PYTHON_EXECUTABLE.
    args = %W[
      -DARCH=generic;ice40;ecp5;machxo2;nexus;mistral;himbaechel
      -DHIMBAECHEL_UARCH=all
      -DPython3_EXECUTABLE=#{python3}
      -DPYTHON_EXECUTABLE=#{python3}
      -DXilinxChipdb_Python3_EXECUTABLE=#{python3}
      -DICESTORM_INSTALL_PREFIX=#{formula_opt_prefix("icestorm")}
      -DICEBOX_DATADIR=#{Formula["icestorm"].opt_pkgshare}/chipdb
      -DTRELLIS_INSTALL_PREFIX=#{formula_opt_prefix("prjtrellis-latest")}
      -DOXIDE_INSTALL_PREFIX=#{formula_opt_prefix("prjoxide")}
      -DAPYCULA_INSTALL_PREFIX=#{formula_opt_libexec("apycula")}
      -DHIMBAECHEL_PRJXRAY_DB=#{deps}/prjxray-db
      -DHIMBAECHEL_PEPPERCORN_PATH=#{deps}/prjpeppercorn
      -DHIMBAECHEL_PRJBEYOND_DB=#{deps}/prjbeyond-db
      -DMISTRAL_ROOT=#{deps}/mistral
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

    # The remaining architectures refuse unconstrained IO, so pin the ports.
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

    # Xilinx 7-series, with the pinout of a Digilent Arty A7-35T.
    xilinx_pins = { "clk" => "E3", "led[0]" => "H5", "led[1]" => "J5", "led[2]" => "T9", "led[3]" => "T10" }
    (testpath/"xilinx.xdc").write xilinx_pins.map { |port, pin|
      "set_property LOC #{pin} [get_ports {#{port}}]\n" \
        "set_property IOSTANDARD LVCMOS33 [get_ports {#{port}}]\n"
    }.join
    system yosys, "-q", "-p", "synth_xilinx -flatten -abc9 -nobram -arch xc7 -top top; " \
                              "write_json xilinx.json", "lfsr.v"
    system bin/"nextpnr-himbaechel", "--device", "xc7a35tcsg324-1", "--json", "xilinx.json",
                                     "--vopt", "xdc=xilinx.xdc", "--vopt", "fasm=xilinx.fasm", "--quiet"
    assert_match "SLICE", (testpath/"xilinx.fasm").read

    # Cologne Chip GateMate.
    (testpath/"gatemate.ccf").write <<~EOS
      Net "clk"    Loc = "IO_SB_A8" | SCHMITT_TRIGGER=true;
      Net "led[0]" Loc = "IO_EB_B1";
      Net "led[1]" Loc = "IO_EB_B2";
      Net "led[2]" Loc = "IO_EB_B3";
      Net "led[3]" Loc = "IO_EB_B4";
    EOS
    system yosys, "-q", "-p", "synth_gatemate -luttree -nomx8 -top top -json gatemate.json", "lfsr.v"
    system bin/"nextpnr-himbaechel", "--device", "CCGM1A1", "--json", "gatemate.json",
                                     "--vopt", "ccf=gatemate.ccf", "--vopt", "out=gatemate.txt", "--quiet"
    assert_path_exists testpath/"gatemate.txt"

    # NanoXplore NG-Ultra. The constraints file has a section of pads, one of
    # bank voltages and one of global clocks, each ended by a "!" line.
    ngultra_pads = { "clk" => "D09P", "led[0]" => "D04P", "led[1]" => "D05P", "led[2]" => "D06P",
                     "led[3]" => "D07P" }
    (testpath/"ngultra.csv").write ngultra_pads.map { |port, pad|
      "#{port},IOB10_#{pad},LVCMOS,2mA,Slow,0,0,False,None,,VT,False,0,0,Auto\n"
    }.join + "!\nIOB10,1.8V,\n!\n"
    system yosys, "-q", "-p", "synth_nanoxplore -family ultra -top top -json ngultra.json", "lfsr.v"
    system bin/"nextpnr-himbaechel", "--device", "NG-ULTRA", "--json", "ngultra.json",
                                     "--vopt", "csv=ngultra.csv", "--vopt", "bit=ngultra.bit.json", "--quiet"
    assert_path_exists testpath/"ngultra.bit.json"

    # Intel (Altera) Cyclone V, through to an RBF bitstream.
    (testpath/"mistral.qsf").write <<~EOS
      set_location_assignment PIN_H1 -to clk
      set_location_assignment PIN_N1 -to {led[0]}
      set_location_assignment PIN_P1 -to {led[1]}
      set_location_assignment PIN_R1 -to {led[2]}
      set_location_assignment PIN_G1 -to {led[3]}
    EOS
    system yosys, "-q", "-p", "synth_intel_alm -family cyclonev -top top; write_json mistral.json", "lfsr.v"
    system bin/"nextpnr-mistral", "--device", "5CEBA2F17A7", "--json", "mistral.json",
                                  "--qsf", "mistral.qsf", "--rbf", "mistral.rbf", "--quiet"
    assert_operator (testpath/"mistral.rbf").size, :>, 0

    # Himbaechel's example architecture: run its built-in self test.
    system bin/"nextpnr-himbaechel", "--device", "EXAMPLE", "--test", "--quiet"

    assert_match "nextpnr-generic", shell_output("#{bin}/nextpnr-generic --version 2>&1")
  end
end

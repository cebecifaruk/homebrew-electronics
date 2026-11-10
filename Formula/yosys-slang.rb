class YosysSlang < Formula
  desc "SystemVerilog frontend for Yosys, built on the slang compiler"
  homepage "https://github.com/povik/sv-elab"
  # The project was renamed from yosys-slang to sv-elab. Its release tarballs
  # omit the slang and fmt submodules, so fetch the tag with git.
  url "https://github.com/povik/sv-elab.git",
      tag:      "2026-11-09",
      revision: "2cfcfbe388b1d8b32e4d31da3449db5bf747c00c"
  license "ISC"
  head "https://github.com/povik/sv-elab.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d{4}-\d{2}-\d{2})$/i)
  end

  depends_on "boost" => :build
  depends_on "cmake" => :build
  depends_on "fmt"
  depends_on "tomlplusplus"
  depends_on "yosys"

  def install
    # Use Homebrew's fmt, tomlplusplus and boost; the bundled copies are
    # pulled in through FetchContent, which Homebrew blocks.
    system "cmake", "-S", ".", "-B", "build",
                    "-DYOSYS_CONFIG=#{formula_opt_bin("yosys")}/yosys-config",
                    "-DUSE_EXTERNAL_FMT=ON",
                    "-DSLANG_USE_SYSTEM_FMT=ON",
                    "-DSLANG_USE_SYSTEM_TOMLPLUSPLUS=ON",
                    "-DSLANG_USE_SYSTEM_BOOST=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    # Upstream's install target writes into the yosys keg's plugin directory,
    # which a formula cannot do, so install the plugin here instead.
    (lib/"yosys/plugins").install "build/slang.so"
  end

  def caveats
    <<~EOS
      Load the plugin into Yosys with its full path:
        yosys -m #{opt_lib}/yosys/plugins/slang.so -p "read_slang design.sv"

      The plugin is tied to the Yosys version it was built against. If Yosys
      fails to load it after a Yosys upgrade, reinstall this formula:
        brew reinstall --build-from-source yosys-slang
    EOS
  end

  test do
    (testpath/"fsm.sv").write <<~SYSTEMVERILOG
      module top(input logic clk, input logic [3:0] a, output logic [3:0] y);
        typedef enum logic [1:0] {IDLE, RUN, DONE} state_t;
        state_t state = IDLE;
        always_ff @(posedge clk) begin
          unique case (state)
            IDLE: state <= RUN;
            RUN:  state <= DONE;
            default: state <= IDLE;
          endcase
        end
        always_comb y = (state == RUN) ? a + 4'd1 : a;
      endmodule
    SYSTEMVERILOG

    yosys = formula_opt_bin("yosys")/"yosys"
    system yosys, "-q", "-m", lib/"yosys/plugins/slang.so",
           "-p", "read_slang fsm.sv; synth -top top; select -assert-any t:*; write_json top.json"
    assert_match "\"top\"", (testpath/"top.json").read
  end
end

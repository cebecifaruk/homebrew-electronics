class PrjtrellisLatest < Formula
  desc "Bitstream tools and database for Lattice ECP5 and MachXO2/3 FPGAs"
  homepage "https://github.com/YosysHQ/prjtrellis"
  # The prjtrellis formula in homebrew/core is release 1.4 (2023), whose
  # database has no MachXO2/MachXO3 timing data, so nextpnr cannot build its
  # MachXO2 architecture against it. The database is a git submodule.
  url "https://github.com/YosysHQ/prjtrellis.git",
      revision: "2d12005ab9703ff60603d7ae91dca254939e671f"
  version "1.4-unstable-2026-10-31"
  license all_of: ["ISC", "MIT"]
  head "https://github.com/YosysHQ/prjtrellis.git", branch: "master"

  livecheck do
    skip "Tracks an unreleased commit"
  end

  keg_only "it installs the same tools and database as `prjtrellis`"

  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "python@3.15"

  def install
    system "cmake", "-S", "libtrellis", "-B", "build",
                    "-DCURRENT_GIT_VERSION=#{version}",
                    "-DPython3_EXECUTABLE=#{formula_opt_bin("python@3.15")}/python3.15",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"ecppll", "-i", "12", "-o", "24", "-f", "pll.v"
    assert_match "EHXPLLL", (testpath/"pll.v").read

    system bin/"ecpbram", "-g", "ram.hex", "-w", "16", "-d", "512"
    assert_equal 512, (testpath/"ram.hex").read.split.size

    # nextpnr's MachXO2 build reads these timing databases.
    %w[MachXO2 MachXO3].each do |family|
      assert_path_exists share/"trellis/database/#{family}/timing"
    end

    python = formula_opt_bin("python@3.15")/"python3.15"
    output = shell_output("#{python} -c 'import sys; sys.path.insert(0, \"#{lib}/trellis\"); " \
                          "import pytrellis; print(pytrellis.__name__)'")
    assert_equal "pytrellis", output.strip
  end
end

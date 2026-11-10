class Gdstk < Formula
  desc "Python and C++ library for creating and manipulating GDSII and OASIS files"
  homepage "https://heitzmann.github.io/gdstk/"
  url "https://files.pythonhosted.org/packages/15/ff/2d378eacd7903db5f90dfaee06c9b737184db01b4c3de93e90d96fdecadb/gdstk-1.0.2.tar.gz"
  sha256 "50a0c534772a2054e3af88d535d36f1a87756a6eaaf8d8c53f5916f66c5d30b1"
  license "BSL-1.0"

  depends_on "cmake" => :build
  depends_on "python-packaging" => :build
  depends_on "numpy"
  depends_on "python@3.15"
  depends_on "qhull"

  uses_from_macos "zlib"

  # Build-time only: the scikit-build-core build backend.
  resource "pathspec" do
    url "https://files.pythonhosted.org/packages/f1/d9/7fb5aa316bc299258e68c73ba3bddbc499654a07f151cba08f6153988714/pathspec-1.1.1-py3-none-any.whl"
    sha256 "a00ce642f577bf7f473932318056212bc4f8bfdf53128c78bbd5af0b9b20b189"
  end

  resource "scikit-build-core" do
    url "https://files.pythonhosted.org/packages/cb/8e/f13e5d7dc75fc979464d5bcc1bc762b07133df3d09d667c34727dfd8b0e8/scikit_build_core-1.1.2-py3-none-any.whl"
    sha256 "7f4f959a467692db50bdd1ea7ce1507f2c7972e6023b753ee302d169bc4cec85"
  end

  def python3
    formula_opt_bin("python@3.15")/"python3.15"
  end

  def install
    build_deps = buildpath/"build-deps"
    resources.each do |r|
      r.stage do
        system python3, "-m", "pip", "install", "--target=#{build_deps}", "--no-deps", "--no-compile",
               Pathname.pwd/r.downloader.basename
      end
    end
    ENV.prepend_path "PYTHONPATH", build_deps

    # gdstk forces a universal (x86_64 + arm64) build on macOS, which fails
    # against Homebrew's single-architecture qhull.
    ENV["CMAKE_ARGS"] = "-DCMAKE_OSX_ARCHITECTURES=#{Hardware::CPU.arch}" if OS.mac?

    # Install into Homebrew's site-packages so that python3.15 can import it.
    system python3, "-m", "pip", "install", *std_pip_args(build_isolation: false), "."
  end

  test do
    (testpath/"test.py").write <<~PYTHON
      import gdstk

      lib = gdstk.Library()
      cell = lib.new_cell("TOP")
      cell.add(gdstk.rectangle((0, 0), (10, 5), layer=1))
      cell.add(gdstk.Polygon([(0, 0), (2, 0), (1, 3)], layer=2))
      lib.write_gds("test.gds")

      top = gdstk.read_gds("test.gds").top_level()[0]
      assert top.name == "TOP"
      assert len(top.polygons) == 2
      print(top.area())
    PYTHON

    assert_equal "53.0", shell_output("#{python3} test.py").strip
    assert_path_exists testpath/"test.gds"
  end
end

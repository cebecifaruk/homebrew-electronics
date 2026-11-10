class Apycula < Formula
  include Language::Python::Virtualenv

  desc "Open-source bitstream tools and chip database for Gowin FPGAs"
  homepage "https://github.com/YosysHQ/apicula"
  url "https://files.pythonhosted.org/packages/46/a8/c47790d71916fbf560dbf54c2df1f6acd8e992511e6c872cfbed171b7c91/apycula-0.35.tar.gz"
  sha256 "1fd15bdcf512eb8eedda48f11dc81fc35236a7ae904b1a887fd6ea44120f37c6"
  license "MIT"

  depends_on "maturin" => :build
  depends_on "python-packaging" => :build
  depends_on "python-setuptools" => :build
  depends_on "rust" => :build
  depends_on "numpy"
  depends_on "python@3.15"

  # Build-time only: needed to read versions from the sdists below.
  resource "vcs-versioning" do
    url "https://files.pythonhosted.org/packages/ad/e7/2a691db7d076b75d099fdba1a14cd966931f2aeb591e77f6d22f15097326/vcs_versioning-2.6.0.tar.gz"
    sha256 "22e9159288e2d8bca2fa6f6c31c34c9c66aec157f60e9e526f5d160d2516d60f"
  end

  resource "setuptools-scm" do
    url "https://files.pythonhosted.org/packages/85/d8/fc143f88819ccf10ba2388ba86732ee2de193e578234e25a783f6cc14bf7/setuptools_scm-10.3.4.tar.gz"
    sha256 "a69f28bfc245608781205e912faae437c2b2165773afa4e7b979d77447a69dd2"
  end

  resource "fastcrc" do
    url "https://files.pythonhosted.org/packages/58/bd/791d8656cd672cc2bc06fda83f5ce369ab5d3b8bf902ee270034d2cae4e8/fastcrc-0.5.0.tar.gz"
    sha256 "e02cdf379d7371f0bd9d7cac957c67f0696e62292d73eebe02ff6393eef05b50"
  end

  resource "msgspec" do
    url "https://files.pythonhosted.org/packages/d0/e6/6dcf9306ff3c5e486578f3bf29ed11dfbdbbc2a8bf0caf7e07d392887fda/msgspec-0.22.0.tar.gz"
    sha256 "0a13624a4969159fe35d8c2a3d377b2b61bbd8585e327440d5e52725affcce38"
  end

  def install
    # Build without isolation so that pip uses the build tools above instead
    # of downloading its own.
    venv = virtualenv_create(libexec, "python3.15")
    venv.pip_install resources, build_isolation: false
    venv.pip_install_and_link buildpath, build_isolation: false
  end

  test do
    system bin/"gowin_pll", "-d", "GW1NR-9 C6/I5", "-i", "27", "-o", "108", "-f", "pll.v"
    assert_match "rPLL", (testpath/"pll.v").read

    # Decode one of the bundled chip databases, as nextpnr's Gowin build does.
    python = libexec/"bin/python"
    script = "from apycula.chipdb import load_chipdb; import apycula, os; " \
             "db = load_chipdb(os.path.join(os.path.dirname(apycula.__file__), 'GW1N-1.msgpack.xz')); " \
             "print(len(db.grid), len(db.grid[0]))"
    rows, cols = shell_output("#{python} -c \"#{script}\"").split.map(&:to_i)
    assert_operator rows, :>, 0
    assert_operator cols, :>, 0
  end
end

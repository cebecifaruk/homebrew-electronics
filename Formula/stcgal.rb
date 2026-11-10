class Stcgal < Formula
  include Language::Python::Virtualenv

  desc "ISP flash tool for STC 8051-compatible microcontrollers"
  homepage "https://github.com/grigorig/stcgal"
  # The PyPI sdist omits doc/PyPI.md, which setup.py reads, so use the tag.
  url "https://github.com/grigorig/stcgal/archive/refs/tags/v1.10.tar.gz"
  sha256 "8fab8d88b3a7649ab691ca5bdfbf331431807f3377ba7af69a9d3e171de3df52"
  license "MIT"

  depends_on "python-packaging" => :build
  depends_on "python-setuptools" => :build
  depends_on "python@3.15"

  # Build-time only: tqdm reads its version with setuptools-scm.
  resource "vcs-versioning" do
    url "https://files.pythonhosted.org/packages/ad/e7/2a691db7d076b75d099fdba1a14cd966931f2aeb591e77f6d22f15097326/vcs_versioning-2.6.0.tar.gz"
    sha256 "22e9159288e2d8bca2fa6f6c31c34c9c66aec157f60e9e526f5d160d2516d60f"
  end

  resource "setuptools-scm" do
    url "https://files.pythonhosted.org/packages/85/d8/fc143f88819ccf10ba2388ba86732ee2de193e578234e25a783f6cc14bf7/setuptools_scm-10.3.4.tar.gz"
    sha256 "a69f28bfc245608781205e912faae437c2b2165773afa4e7b979d77447a69dd2"
  end

  resource "pyserial" do
    url "https://files.pythonhosted.org/packages/1e/7d/ae3f0a63f41e4d2f6cb66a5b57197850f919f59e558159a4dd3a818f5082/pyserial-3.5.tar.gz"
    sha256 "3c77e014170dfffbd816e6ffc205e9842efb10be9f58ec16d3e8675b4925cddb"
  end

  resource "tqdm" do
    url "https://files.pythonhosted.org/packages/0d/ea/b2a5bd54b28a324dae8211928b2d730b6547500342c7e6c6dea08bd0a485/tqdm-4.70.1.tar.gz"
    sha256 "cefd0eca11b2a37a3aee776544d4f4ae913f02688135b5556b8788dfa474afc4"
  end

  def install
    # Build without isolation so that pip uses the build tools above instead
    # of downloading its own.
    venv = virtualenv_create(libexec, "python3.15")
    venv.pip_install resources, build_isolation: false
    venv.pip_install_and_link buildpath, build_isolation: false
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/stcgal --version")
    # No board is attached; stcgal fails to open the port.
    output = shell_output("#{bin}/stcgal -p /dev/does-not-exist 2>&1", 1)
    assert_match "does-not-exist", output
  end
end

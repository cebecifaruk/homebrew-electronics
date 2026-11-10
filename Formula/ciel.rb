class Ciel < Formula
  include Language::Python::Virtualenv

  desc "Version manager and builder for open-source process design kits (PDKs)"
  homepage "https://github.com/fossi-foundation/ciel"
  url "https://files.pythonhosted.org/packages/26/72/2dbea0d3ca2a5abee310ba9be07747c7d8172919838a8a8a91eb065aab6d/ciel-3.2.0.tar.gz"
  sha256 "96d8faa5330f4f8a23ca10c76470ecf6f8a46b5dd85bbcbc25698872d919e1e8"
  license "Apache-2.0"

  depends_on "cython" => :build
  depends_on "python-packaging" => :build
  depends_on "python-setuptools" => :build
  depends_on "certifi"
  depends_on "cffi"
  depends_on "libyaml"
  depends_on "python@3.15"

  # Build-time only: ciel's build backend.
  resource "poetry-core" do
    url "https://files.pythonhosted.org/packages/b7/25/7ed0a2ea4fe12f7fd0394387b5debbcd6fdbd06e5ac9daab96ba11471da8/poetry_core-2.5.0-py3-none-any.whl"
    sha256 "98ee465b66f7e14bb9fbe68fb5e00d0cff184f036993ec94610ae4b5612f3add"
  end

  resource "anyio" do
    url "https://files.pythonhosted.org/packages/a9/16/7757fb84c819accc7d7e9af5291b261e4abb8627ee040f99e7d35ef2457a/anyio-4.16.0-py3-none-any.whl"
    sha256 "c66ae634e0b8228396b801741beb3294326d4b6102f7bba4041c0dfb58c29026"
  end

  resource "click" do
    url "https://files.pythonhosted.org/packages/fb/e2/79c688af8b210d232694e31e59da9f6ec747bae31c3f5946e4e9b98860d5/click-8.4.2-py3-none-any.whl"
    sha256 "e6f9f66136c816745b9d65817da91d61d957fb16e02e4dcd0552553c5a197b76"
  end

  resource "h11" do
    url "https://files.pythonhosted.org/packages/04/4b/29cac41a4d98d144bf5f6d33995617b185d14b22401f75ca86f384e87ff1/h11-0.16.0-py3-none-any.whl"
    sha256 "63cf8bbe7522de3bf65932fda1d9c2772064ffb3dae62d55932da54b31cb6c86"
  end

  resource "httpcore" do
    url "https://files.pythonhosted.org/packages/7e/f5/f66802a942d491edb555dd61e3a9961140fd64c90bce1eafd741609d334d/httpcore-1.0.9-py3-none-any.whl"
    sha256 "2d400746a40668fc9dec9810239072b40b4484b640a8c38fd654a024c7a1bf55"
  end

  resource "httpx" do
    url "https://files.pythonhosted.org/packages/2a/39/e50c7c3a983047577ee07d2a9e53faf5a69493943ec3f6a384bdc792deb2/httpx-0.28.1-py3-none-any.whl"
    sha256 "d909fcccc110f8c7faf814ca82a9a4d816bc5a6dbfea25d6591d6985b8ba59ad"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/58/a2/bb081bab032533a855d44de1d56f8e8426114ff1ba5d1f07a438a0a654f8/idna-3.20-py3-none-any.whl"
    sha256 "ab7ae7122974553370f0bdb919e1a960b2cd1bc1ef0276416d896db81c14582c"
  end

  resource "markdown-it-py" do
    url "https://files.pythonhosted.org/packages/b3/81/4da04ced5a082363ecfa159c010d200ecbd959ae410c10c0264a38cac0f5/markdown_it_py-4.2.0-py3-none-any.whl"
    sha256 "9f7ebbcd14fe59494226453aed97c1070d83f8d24b6fc3a3bcf9a38092641c4a"
  end

  resource "mdurl" do
    url "https://files.pythonhosted.org/packages/b3/38/89ba8ad64ae25be8de66a6d463314cf1eb366222074cfda9ee839c56a4b4/mdurl-0.1.2-py3-none-any.whl"
    sha256 "84008a41e51615a49fc9966191ff91509e3c40b939176e643fd50a5c2196b8f8"
  end

  resource "pcpp" do
    url "https://files.pythonhosted.org/packages/01/ca/ada7f39c5a0977893e0ef809b1617b259b2d76f6382a7abad00dd6d77904/pcpp-1.30-py2.py3-none-any.whl"
    sha256 "05fe08292b6da57f385001c891a87f40d6aa7f46787b03e8ba326d20a3297c6e"
  end

  resource "pygments" do
    url "https://files.pythonhosted.org/packages/71/46/17f022dd3e953bf20a04a028a21ec746d942f8d2af30fa0f124fa0e6a684/pygments-2.21.0-py3-none-any.whl"
    sha256 "2363c69b61c4a97c838da3b130dcd6468f4848992b21a82f2a63ec34377137d9"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  resource "rich" do
    url "https://files.pythonhosted.org/packages/82/3b/64d4899d73f91ba49a8c18a8ff3f0ea8f1c1d75481760df8c68ef5235bf5/rich-15.0.0-py3-none-any.whl"
    sha256 "33bd4ef74232fb73fe9279a257718407f169c09b78a87ad3d296f548e27de0bb"
  end

  resource "zstandard" do
    url "https://files.pythonhosted.org/packages/fd/aa/3e0508d5a5dd96529cdc5a97011299056e14c6505b678fd58938792794b1/zstandard-0.25.0.tar.gz"
    sha256 "7713e1179d162cf5c7906da876ec2ccb9c3a9dcbdffef0cc7f70c3667a205f0b"
  end

  def install
    # PyYAML's C extension needs Cython, which the cython formula keeps in
    # its own libexec rather than in the shared site-packages.
    ENV.prepend_path "PYTHONPATH", formula_opt_libexec("cython")/"lib/python3.15/site-packages"

    # Build without isolation so that pip uses the build tools above instead
    # of downloading its own.
    venv = virtualenv_create(libexec, "python3.15")
    venv.pip_install resources, build_isolation: false
    venv.pip_install_and_link buildpath, build_isolation: false
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ciel --version")

    # Lists locally installed PDKs; offline, and the root starts out empty.
    pdk_root = testpath/"pdks"
    pdk_root.mkpath
    output = shell_output("#{bin}/ciel ls --pdk-root #{pdk_root} --pdk-family sky130")
    assert_empty output.strip

    python = libexec/"bin/python"
    system python, "-c", "import yaml, zstandard; assert yaml.__with_libyaml__"
  end
end

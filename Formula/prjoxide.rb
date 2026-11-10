class Prjoxide < Formula
  desc "Bitstream tools and chip database for Lattice Nexus FPGAs"
  homepage "https://github.com/gatecat/prjoxide"
  # No releases are tagged, and the database lives in a git submodule, so
  # fetch a pinned commit with git.
  url "https://github.com/gatecat/prjoxide.git",
      revision: "ea3fe12094dec200afcecdf9ed3306f82e6e3eb2"
  version "0.1-unstable-2026-07-19"
  license "ISC"
  head "https://github.com/gatecat/prjoxide.git", branch: "master"

  livecheck do
    skip "No tagged releases"
  end

  depends_on "rust" => :build

  def install
    # Upstream ships no Cargo.lock, so std_cargo_args (which passes --locked)
    # cannot be used.
    system "cargo", "install", "--jobs", ENV.make_jobs.to_s,
                               "--root=#{prefix}",
                               "--path=libprjoxide/prjoxide"
  end

  test do
    assert_match "prjoxide", shell_output("#{bin}/prjoxide --version")

    # nextpnr's Nexus build runs this to generate its chip database.
    (testpath/"constids.inc").write ""
    system bin/"prjoxide", "bba-export", "LIFCL", "constids.inc", "chipdb.bba"
    assert_match "chipdb_blob_LIFCL", File.read(testpath/"chipdb.bba", 4096)
  end
end

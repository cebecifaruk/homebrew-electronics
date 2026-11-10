class Freerouting < Formula
  desc "Autorouter for printed circuit boards (Specctra DSN/SES)"
  homepage "https://freerouting.app/"
  url "https://github.com/freerouting/freerouting/releases/download/v2.5.0/freerouting-2.5.0.jar"
  sha256 "f6f51bb02245e8e717f9359bd260cc9c5c0b1bc0acc8b7cb2cd5b8ffeb5de3c7"
  license "GPL-3.0-only"

  # The jar is built for Java 25 (class file version 69).
  depends_on "openjdk"

  def install
    libexec.install "freerouting-#{version}.jar" => "freerouting.jar"
    bin.write_jar_script libexec/"freerouting.jar", "freerouting"
  end

  test do
    # Route the tutorial board that ships inside the jar, without the GUI.
    system formula_opt_bin("openjdk")/"jar", "xf", libexec/"freerouting.jar", "tutorial_board.dsn"
    ENV["JAVA_TOOL_OPTIONS"] = "-Djava.awt.headless=true"
    system bin/"freerouting", "--gui.enabled=false", "-de", "tutorial_board.dsn",
                              "-do", "tutorial_board.ses", "-mp", "2"
    assert_match "(session \"tutorial_board\"", (testpath/"tutorial_board.ses").read
  end
end

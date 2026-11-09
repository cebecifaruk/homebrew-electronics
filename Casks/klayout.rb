cask "klayout" do
  version "0.30.13"

  # Upstream builds a separate DMG for each macOS release. These are the "ST"
  # (standard) builds: they use the Ruby and Python that ship with macOS and
  # bundle Qt5 from MacPorts.
  on_sonoma :or_older do
    sha256 "b360f97f1d1e23ebcef7991a862522c5dc8ecafeb2ce528522452cc778ca52df"

    url "https://www.klayout.org/downloads/MacOS/ST-klayout-#{version}-macOS-Sonoma-C32-1-qt5MP-RsysPsys.dmg"
  end
  on_sequoia do
    sha256 "8b479b6109ed8a888fcc2e46d9ae1ef2d74a45cf62b9e2a407bcb5f19b294ebc"

    url "https://www.klayout.org/downloads/MacOS/ST-klayout-#{version}-macOS-Sequoia-C32-1-qt5MP-RsysPsys.dmg"
  end
  on_tahoe do
    on_arm do
      sha256 "4e8ec08ce8b314c873bfd3961ff7d476608357770b752406d4e36a939d75cea3"

      url "https://www.klayout.org/downloads/MacOS/ARM64/arm64ST-klayout-#{version}-macOS-Tahoe-C32-1-qt5MP-RsysPsys.dmg"
    end
    on_intel do
      # There is no Intel build for Tahoe; the Sequoia build runs on it.
      sha256 "8b479b6109ed8a888fcc2e46d9ae1ef2d74a45cf62b9e2a407bcb5f19b294ebc"

      url "https://www.klayout.org/downloads/MacOS/ST-klayout-#{version}-macOS-Sequoia-C32-1-qt5MP-RsysPsys.dmg"
    end
  end
  on_golden_gate :or_newer do
    sha256 "18853b8445675c90e58f99b3391d8c4504a5ddb7cb45cdef04dd81c58ad8bef1"

    url "https://www.klayout.org/downloads/MacOS/ARM64/arm64ST-klayout-#{version}-macOS-GoldenGate-C32-1-qt5MP-RsysPsys.dmg"
  end

  name "KLayout"
  desc "IC design layout viewer and editor"
  homepage "https://www.klayout.de/"

  livecheck do
    url "https://www.klayout.de/build.html"
    regex(/href=.*?ST[._-]klayout[._-]v?(\d+(?:\.\d+)+)[._-]macOS/i)
  end

  depends_on macos: :sonoma

  app "klayout.app"
  binary "#{appdir}/klayout.app/Contents/MacOS/klayout"

  uninstall quit: "de.klayout"

  zap trash: [
    "~/.klayout",
    "~/Library/Preferences/de.klayout.plist",
    "~/Library/Saved Application State/de.klayout.savedState",
  ]

  caveats <<~EOS
    #{token} uses the Ruby and Python that ship with macOS, which need the
    Xcode Command Line Tools. Install them with:
      xcode-select --install

    Upstream signs #{token} ad hoc and does not notarize it, so Gatekeeper
    blocks the first launch. To allow it, open klayout.app once, then click
    "Open Anyway" in System Settings > Privacy & Security, or run:
      xattr -dr com.apple.quarantine #{appdir}/klayout.app
  EOS
end

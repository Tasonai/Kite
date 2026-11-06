cask "kite" do
  version "1.3.0"
  sha256 "f19209f354927073a3c2870898e5f34eb48fb0494e44392cd4431aea8c4229a2"

  url "https://github.com/Tasonai/Kite/releases/download/v#{version}/Kite-#{version}-macOS.dmg"
  name "Kite"
  desc "Studio for ideas, architecture and Antigravity skills"
  homepage "https://github.com/Tasonai/Kite"

  depends_on macos: :sequoia

  app "Kite.app"

  zap trash: [
    "~/Library/Application Support/Kite",
    "~/Library/Preferences/com.chase.kite.plist",
  ]
end

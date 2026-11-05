cask "kite" do
  version "1.2.0"
  sha256 "c75cebd8f84fbbfc74c840963e74357a10fbe1af56ffaea7a79674503d32b5b9"

  url "https://github.com/Tasonai/Kite/releases/download/v#{version}/Kite-#{version}-macOS.dmg"
  name "Kite"
  desc "Studio for ideas, architecture and Antigravity skills"
  homepage "https://github.com/Tasonai/Kite"

  depends_on macos: ">= :sonoma"

  app "Kite.app"

  zap trash: [
    "~/Library/Application Support/Kite",
    "~/Library/Preferences/com.chase.kite.plist",
  ]
end

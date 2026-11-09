cask "kite" do
  version "1.4.0"
  sha256 "0d48d84607aa1e58921ca756ae9728a06d2807c3b439988af23d673b9a15e12b"

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

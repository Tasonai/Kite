cask "kite" do
  version "1.5.0"
  sha256 "a4a9aec004aae4b0ba21b9b4141e7ba27f8647b9dd2ad0022e8573a576a66e5c"

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

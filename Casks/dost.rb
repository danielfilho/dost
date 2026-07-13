cask "dost" do
  version "1.3.0"
  sha256 "c013c493aec18729cb1f277aabdb4c892bdac15776fca5bd47759bfcf6c4b656"

  url "https://github.com/danielfilho/dost/releases/download/v#{version}/dost-#{version}.zip"
  name "dost"
  desc "AnyBar-compatible status indicators in a floating always-on-top window"
  homepage "https://github.com/danielfilho/dost"

  depends_on macos: :ventura

  app "dost.app"
  binary "#{appdir}/dost.app/Contents/MacOS/dost"

  zap trash: "~/Library/Preferences/dev.danielfilho.dost.settings.plist"
end

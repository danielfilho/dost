cask "dost" do
  version "1.1.0"
  sha256 "b10239e81c86a326a7c1d907bd500d4e3513ca1aa303758104cf8d859e3c05f9"

  url "https://github.com/danielfilho/dost/releases/download/v#{version}/dost-#{version}.zip"
  name "dost"
  desc "AnyBar-compatible status indicators in a floating always-on-top window"
  homepage "https://github.com/danielfilho/dost"

  depends_on macos: ">= :ventura"

  app "dost.app"

  zap trash: "~/Library/Preferences/dev.danielfilho.dost.settings.plist"
end

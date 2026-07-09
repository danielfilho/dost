cask "dost" do
  version "1.2.0"
  sha256 "c181af55ff4bb3f954dcb4d83d9bab5e70d9bf5b6c286de6f14890581cf40226"

  url "https://github.com/danielfilho/dost/releases/download/v#{version}/dost-#{version}.zip"
  name "dost"
  desc "AnyBar-compatible status indicators in a floating always-on-top window"
  homepage "https://github.com/danielfilho/dost"

  depends_on macos: :ventura

  app "dost.app"
  binary "#{appdir}/dost.app/Contents/MacOS/dost"

  zap trash: "~/Library/Preferences/dev.danielfilho.dost.settings.plist"
end

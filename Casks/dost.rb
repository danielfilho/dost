cask "dost" do
  version "1.2.1"
  sha256 "ae3c05d9c66fcb47b197216a1b9f8cf86b921e2e89efdbe91236781d73ba02df"

  url "https://github.com/danielfilho/dost/releases/download/v#{version}/dost-#{version}.zip"
  name "dost"
  desc "AnyBar-compatible status indicators in a floating always-on-top window"
  homepage "https://github.com/danielfilho/dost"

  depends_on macos: :ventura

  app "dost.app"
  binary "#{appdir}/dost.app/Contents/MacOS/dost"

  zap trash: "~/Library/Preferences/dev.danielfilho.dost.settings.plist"
end

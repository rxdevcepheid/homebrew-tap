class Proguard411 < Formula
  desc "Java class file shrinker, optimizer, and obfuscator"
  homepage "http://proguard.sourceforge.net/"
  url "https://sourceforge.net/projects/proguard/files/proguard/4.11/proguard4.11.tar.gz"
  version "4.11"
  sha256 "90a4dbf8c016fd84da6d48d8b16e450ee07abafbfb7bb6eb5028651a8c255d9e"

  bottle :unneeded

  def install
    libexec.install "lib/proguard.jar"
    libexec.install "lib/proguardgui.jar"
    bin.write_jar_script libexec/"proguard.jar", "proguard"
    bin.write_jar_script libexec/"proguardgui.jar", "proguardgui"
  end

  test do
    expect = <<-EOS.undent
      ProGuard, version #{version}
      Usage: java proguard.ProGuard [options ...]
    EOS
    assert_equal expect, shell_output("#{bin}/proguard", 1)
  end
end

class ErlangR192 < Formula
  desc "Erlang Programming Language"
  homepage "http://www.erlang.org"
  url "https://github.com/erlang/otp/archive/OTP-19.2.tar.gz"
  sha256 "c6adbc82a45baa49bf9f5b524089da480dd27113c51b3d147aeb196fdb90516b"

  bottle do
    cellar :any
    sha256 "77dc8acc693bda09f9e06fd36196d4aa6e3320585c1012b879ab4cd79a7f6322" => :el_capitan
    sha256 "bffc4c45b983c1e562c46d060f0ca1bbac9f503260822900be24b6fe52e554b6" => :yosemite
    sha256 "1766be0dab06499049b27929a1ca16ae67719bc568026e546be687462f5a15a0" => :mavericks
  end

  option "without-hipe", "Disable building hipe; fails on various OS X systems"
  option "with-native-libs", "Enable native library compilation"
  option "with-dirty-schedulers", "Enable experimental dirty schedulers"
  option "without-docs", "Do not install documentation"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "openssl"
  depends_on "unixodbc" if MacOS.version >= :mavericks
  depends_on "fop" => :optional # enables building PDF docs
  depends_on "wxmac" => :optional # for GUI apps like observer

  conflicts_with "erlang", :because => "Different version of same formula"

  resource "man" do
    url "http://www.erlang.org/download/otp_doc_man_19.2.tar.gz"
    sha256 "8a76ff3bb40a6d6a1552fa5a4204c8a3c7d99d2ea6f12684f02d038b23ad25cb"
  end

  resource "html" do
    url "http://www.erlang.org/download/otp_doc_html_19.2.tar.gz"
    sha256 "c373c8c1a9fe7433825088684932f3ded76f53d5b8a4d3d2a364263f1f783043"
  end

  def install
    # Unset these so that building wx, kernel, compiler and
    # other modules doesn't fail with an unintelligable error.
    %w[LIBS FLAGS AFLAGS ZFLAGS].each { |k| ENV.delete("ERL_#{k}") }

    ENV["FOP"] = "#{HOMEBREW_PREFIX}/bin/fop" if build.with? "fop"

    # Do this if building from a checkout to generate configure
    system "./otp_build", "autoconf" if File.exist? "otp_build"

    args = %W[
      --disable-debug
      --disable-silent-rules
      --prefix=#{prefix}
      --enable-kernel-poll
      --enable-threads
      --enable-sctp
      --enable-dynamic-ssl-lib
      --with-ssl=#{Formula["openssl"].opt_prefix}
      --enable-shared-zlib
      --enable-smp-support
    ]

    args << "--enable-darwin-64bit" if MacOS.prefer_64_bit?
    args << "--enable-native-libs" if build.with? "native-libs"
    args << "--enable-dirty-schedulers" if build.with? "dirty-schedulers"
    args << "--enable-wx" if build.with? "wxmac"

    if MacOS.version >= :snow_leopard && MacOS::CLT.installed?
      args << "--with-dynamic-trace=dtrace"
    end

    if build.without? "hipe"
      # HIPE doesn't strike me as that reliable on OS X
      # http://syntatic.wordpress.com/2008/06/12/macports-erlang-bus-error-due-to-mac-os-x-1053-update/
      # http://www.erlang.org/pipermail/erlang-patches/2008-September/000293.html
      args << "--disable-hipe"
    else
      args << "--enable-hipe"
    end

    system "./configure", *args
    system "make"
    ENV.deparallelize # Install is not thread-safe; can try to create folder twice and fail
    system "make", "install"

    if build.with? "docs"
      (lib/"erlang").install resource("man").files("man")
      doc.install resource("html")
    end
  end

  def caveats; <<-EOS.undent
    Man pages can be found in:
      #{opt_lib}/erlang/man

    Access them with `erl -man`, or add this directory to MANPATH.
    EOS
  end

  test do
    system "#{bin}/erl", "-noshell", "-eval", "crypto:start().", "-s", "init", "stop"
  end
end

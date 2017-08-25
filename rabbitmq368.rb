# Documentation: https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Formula-Cookbook.md
#                http://www.rubydoc.info/github/Homebrew/homebrew/master/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Rabbitmq368 < Formula
  desc "Messaging broker"
  homepage "https://www.rabbitmq.com"
  url "https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.8/rabbitmq-server-mac-standalone-3.6.8.tar.xz"
  version "3.6.8"
  sha256 "9c3ece6695d0369f17f6c543fde16c50421e3a9bb5bb455403f5e51a4f897a70"

  bottle :unneeded

  def install
    # Install the base files
    prefix.install Dir["*"]

    # Setup the lib files
    (var+"lib/rabbitmq").mkpath
    (var+"log/rabbitmq").mkpath

    # Correct SYS_PREFIX for things like rabbitmq-plugins
    inreplace sbin/"rabbitmq-defaults" do |s|
      s.gsub! "SYS_PREFIX=${RABBITMQ_HOME}", "SYS_PREFIX=#{HOMEBREW_PREFIX}"
      s.gsub! 'CLEAN_BOOT_FILE="${SYS_PREFIX}/releases/3.4.4/start_clean"', 'CLEAN_BOOT_FILE="${RABBITMQ_HOME}/releases/3.4.4/start_clean"'
      s.gsub! 'SASL_BOOT_FILE="${SYS_PREFIX}/releases/3.4.4/start_sasl"', 'SASL_BOOT_FILE="${RABBITMQ_HOME}/releases/3.4.4/start_sasl"'
    end

    # Set RABBITMQ_HOME in rabbitmq-env
    inreplace (sbin + "rabbitmq-env"), 'RABBITMQ_HOME="${SCRIPT_DIR}/.."', "RABBITMQ_HOME=#{prefix}"

    # Create the rabbitmq-env.conf file
    rabbitmq_env_conf = etc+"rabbitmq/rabbitmq-env.conf"
    rabbitmq_env_conf.write rabbitmq_env unless rabbitmq_env_conf.exist?

    # Enable plugins - management web UI and visualiser; STOMP, MQTT, AMQP 1.0 protocols
    enabled_plugins_path = etc+"rabbitmq/enabled_plugins"
    enabled_plugins_path.write "[rabbitmq_management,rabbitmq_management_visualiser,rabbitmq_stomp,rabbitmq_amqp1_0,rabbitmq_mqtt]." unless enabled_plugins_path.exist?

    # Extract rabbitmqadmin and install to sbin
    # use it to generate, then install the bash completion file
    system "/usr/bin/unzip", "-qq", "-j",
           "#{prefix}/plugins/rabbitmq_management-#{version}.ez",
           "rabbitmq_management-#{version}/priv/www/cli/rabbitmqadmin"

    sbin.install "rabbitmqadmin"
    (sbin/"rabbitmqadmin").chmod 0755
    (bash_completion/"rabbitmqadmin.bash").write `#{sbin}/rabbitmqadmin --bash-completion`
  end

  def caveats; <<-EOS.undent
    Management Plugin enabled by default at http://localhost:15672
    EOS
  end


  test do
    ENV["RABBITMQ_MNESIA_BASE"] = testpath/"var/lib/rabbitmq/mnesia"
    system sbin/"rabbitmq-server", "-detached"
    system sbin/"rabbitmqctl", "status"
    system sbin/"rabbitmqctl", "stop"
  end

  def rabbitmq_env; <<-EOS.undent
    CONFIG_FILE=#{etc}/rabbitmq/rabbitmq
    NODE_IP_ADDRESS=127.0.0.1
    NODENAME=rabbit@localhost
    EOS
  end

  plist_options :manual => "rabbitmq-server"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>Program</key>
        <string>#{opt_sbin}/rabbitmq-server</string>
        <key>RunAtLoad</key>
        <true/>
        <key>EnvironmentVariables</key>
        <dict>
          <!-- need erl in the path -->
          <key>PATH</key>
          <string>#{HOMEBREW_PREFIX}/sbin:/usr/bin:/bin:#{HOMEBREW_PREFIX}/bin</string>
          <!-- specify the path to the rabbitmq-env.conf file -->
          <key>CONF_ENV_FILE</key>
          <string>#{etc}/rabbitmq/rabbitmq-env.conf</string>
        </dict>
      </dict>
    </plist>
    EOS
  end

end
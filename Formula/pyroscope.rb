class Pyroscope < Formula
  desc "Open source continuous profiling software"
  homepage "https://pyroscope.io"
  url "https://dl.pyroscope.io/release/pyroscope-0.5.1-source.tar.gz"
  sha256 "a5f138a04a7a3b31c9e693370d9c214e3a6724fe14fbe123f8b7adc4ae28aff3"
  license "Apache-2.0"
  head "https://github.com/pyroscope-io/pyroscope.git", branch: "main"

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "rust" => :build
  depends_on "yarn" => :build
  depends_on "zstd" => :build

  on_linux do
    depends_on "libunwind"
    depends_on "php"
    depends_on "gcc"
  end

  fails_with gcc: "5"

  def install
    system "make", "build-third-party-dependencies"
    system "make", "install-build-web-dependencies"
    system "make", "build-release"

    bin.install "bin/pyroscope"
  end

  def post_install
    (var/"log/pyroscope").mkpath
    (var/"lib/pyroscope").mkpath
    (etc/"pyroscope").mkpath
  end

  service do
    run [bin/"pyroscope", "server"]
  end

  test do
    require "timeout"

    assert_match version.to_s, shell_output("#{bin}/pyroscope version 2>&1")

    port = free_port

    pid = fork do
      exec bin/"pyroscope", "server", "-storage-path", testpath/"lib/pyroscope", "-api-bind-addr", ":#{port}"
    end

    sleep 10

    output = shell_output("curl http://localhost:#{port}/config")
    assert_match(/LogLevel/, output)

  ensure
    Process.kill("HUP", pid)
  end
end

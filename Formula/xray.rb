class Xray < Formula
  desc "Platform for building proxies to bypass network restrictions"
  homepage "https://xtls.github.io/"
  url "https://github.com/XTLS/Xray-core/archive/v1.5.2.tar.gz"
  sha256 "b687a8fd1325bee0f6352c8dc3bfb70a7ee07cd74aacaece4e36c93cf7cda417"
  license all_of: ["MPL-2.0", "CC-BY-SA-4.0"]
  head "https://github.com/XTLS/Xray-core.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_monterey: "88d3157297bd0338b65a2ddc084609112154c3657ee352b5869840ebad286ab5"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "ea9626bccd0b70aac0880d33f1d34bac66285f529d16d51e78e68b504fe1f76c"
    sha256 cellar: :any_skip_relocation, monterey:       "c870a48767aa293615e91434871faa98c15ea7706b9198c301d4dd17439e3fd8"
    sha256 cellar: :any_skip_relocation, big_sur:        "5347284834dfeda1150dfae1831341be14f12cfd983641da9bd6b49488fd4053"
    sha256 cellar: :any_skip_relocation, catalina:       "42ed8b7eb67b83f0b560363f3a61ee0b3e7a698cb697df08e9a06453a9db4c74"
    sha256 cellar: :any_skip_relocation, mojave:         "47d081dfe999470fbbb7b1b64ce18c0fad7362be4b68d696db87a571c71f540d"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "3fc53062e26cc87199a676071958fc5f458baae4c68530c7f9315f988d7ed599"
  end

  depends_on "go" => :build

  resource "geoip" do
    url "https://github.com/v2fly/geoip/releases/download/202201060033/geoip.dat"
    sha256 "27f9cf6d647f018be425188a25ceb095076f6d29544bac843c2d51e0000d00a0"
  end

  resource "geosite" do
    url "https://github.com/v2fly/domain-list-community/releases/download/20220108151752/dlc.dat"
    sha256 "f1961b28a8a7aa386d69c7480bf5d7bac7fa466fb8dcba499ed2d964f470d9fc"
  end

  resource "example_config" do
    # borrow v2ray example config
    url "https://raw.githubusercontent.com/v2fly/v2ray-core/v4.44.0/release/config/config.json"
    sha256 "1bbadc5e1dfaa49935005e8b478b3ca49c519b66d3a3aee0b099730d05589978"
  end

  def install
    ldflags = "-s -w -buildid="
    execpath = libexec/name
    system "go", "build", *std_go_args(output: execpath, ldflags: ldflags), "./main"
    (bin/"xray").write_env_script execpath,
      XRAY_LOCATION_ASSET: "${XRAY_LOCATION_ASSET:-#{pkgshare}}"

    pkgshare.install resource("geoip")
    resource("geosite").stage do
      pkgshare.install "dlc.dat" => "geosite.dat"
    end
    pkgetc.install resource("example_config")
  end

  def caveats
    <<~EOS
      An example config is installed to #{etc}/xray/config.json
    EOS
  end

  service do
    run [opt_bin/"xray", "run", "--config", "#{etc}/xray/config.json"]
    run_type :immediate
    keep_alive true
  end

  test do
    (testpath/"config.json").write <<~EOS
      {
        "log": {
          "access": "#{testpath}/log"
        },
        "outbounds": [
          {
            "protocol": "freedom",
            "tag": "direct"
          }
        ],
        "routing": {
          "rules": [
            {
              "ip": [
                "geoip:private"
              ],
              "outboundTag": "direct",
              "type": "field"
            },
            {
              "domains": [
                "geosite:private"
              ],
              "outboundTag": "direct",
              "type": "field"
            }
          ]
        }
      }
    EOS
    output = shell_output "#{bin}/xray -c #{testpath}/config.json -test"

    assert_match "Configuration OK", output
    assert_predicate testpath/"log", :exist?
  end
end

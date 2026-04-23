class Tyrion < Formula
  desc "Small but capable programming language"
  homepage "https://github.com/tyrionic/tyrionic"
  version "0.1.3"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/tyrionic/tyrionic/releases/download/v0.1.3/tyrion_macos_aarch64"
      sha256 "7f8f188686adea05634f204ab1bf931231c7687f06e67ddb81fbbc8c683c8550"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/tyrionic/tyrionic/releases/download/v0.1.3/tyrion_linux_x86"
      sha256 "25eb03d1e8869dab80840755e02d1df154dfeeeba61692f5f10802f4d92f338c"
    end
    on_arm do
      url "https://github.com/tyrionic/tyrionic/releases/download/v0.1.3/tyrion_linux_aarch64"
      sha256 "62132152f20b84a7a07472cb97317b88223d69f1155c7897a27f1a5b3384f0a8"
    end
  end

  resource "tyrion_source" do
    url "https://github.com/tyrionic/tyrionic/archive/refs/tags/v#{version}.tar.gz"
    sha256 "8660da529e0b512c20d20ea00841a9b65baf63d10e52d74bfafad1b277e5e253"
  end

  def install
    binary_name =
      if OS.mac?
        odie "Tyrion bottles currently support Apple Silicon macOS only" unless Hardware::CPU.arm?
        "tyrion_macos_aarch64"
      elsif OS.linux?
        Hardware::CPU.arm? ? "tyrion_linux_aarch64" : "tyrion_linux_x86"
      else
        odie "Unsupported platform for Tyrion"
      end

    source_binary = buildpath/binary_name
    odie "Expected prebuilt binary missing: #{source_binary}" unless source_binary.exist?

    libexec.install source_binary => "tyrion-compiler"

    (bin/"tyrionc").write <<~EOS
      #!/bin/bash
      set -euo pipefail
      ext_dir="#{pkgshare}/extensions"
      has_ext_dir=0
      for arg in "$@"; do
        case "$arg" in
          --ext-dir|--ext-dir=*)
            has_ext_dir=1
            ;;
        esac
      done
      if [[ "$has_ext_dir" -eq 0 ]]; then
        exec "#{libexec}/tyrion-compiler" --ext-dir "$ext_dir" "$@"
      fi
      exec "#{libexec}/tyrion-compiler" "$@"
    EOS
    chmod 0755, bin/"tyrionc"
    (bin/"tyrion").make_symlink "tyrionc"
    (bin/"tyrionic").make_symlink "tyrionc"

    resource("tyrion_source").stage do
      pkgshare.install "tyrionc.ty"
      pkgshare.install "extensions"
    end
  end

  test do
    assert_match "tyrionc", shell_output("TYRION_ALLOW_STAGE_SNAPSHOT_HANDOFF=0 #{bin}/tyrionc --version")
    assert_match "tyrionc", shell_output("TYRION_ALLOW_STAGE_SNAPSHOT_HANDOFF=0 #{bin}/tyrion --version")
    assert_match "tyrionc", shell_output("TYRION_ALLOW_STAGE_SNAPSHOT_HANDOFF=0 #{bin}/tyrionic --version")
    assert_predicate pkgshare/"tyrionc.ty", :exist?
    assert_predicate pkgshare/"extensions", :exist?
    assert_predicate pkgshare/"extensions/README.md", :exist?
  end
end

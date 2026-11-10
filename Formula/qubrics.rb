class Qubrics < Formula
  desc "Command-line access to Qubrics APIs"
  homepage "https://qubrics.com/docs"
  url "https://registry.npmjs.org/@qubrics/cli/-/cli-2.0.0.tgz"
  sha256 "2431314e4e3d4e485b5935a6b74921c09f005e82ebb4bab519d77c6d8911a799"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/qubrics --version")
    assert_match "qubrics", shell_output("#{bin}/qubrics --help")
  end
end

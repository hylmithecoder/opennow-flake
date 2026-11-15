{ lib, stdenv, appimageTools, fetchurl }:

let
  pname = "opennow";
  version = "1.0.5";

  sources = {
    x86_64-linux = {
      arch = "x64";
      hash = "sha256-HCGRBeYwBItktV0CwFhOQlWwG2nLgujnBgOSim6TEOY=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-1VBSUHC78kqTrNkpi3wZFYxoMnc76becQIJ1G4rt4J0=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "opennow: unsupported system ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/OpenCloudGaming/OpenNOW/releases/download/v${version}/OpenNOW-Qt-${version}-Linux-${source.arch}.AppImage";
    inherit (source) hash;
  };

  appimageContents = appimageTools.extract { inherit pname version src; };

  # OpenNOW plays game audio by piping raw PCM into `/usr/bin/pw-cat --latency 10ms`.
  # 10ms is too tight (especially behind EasyEffects): PipeWire underruns, and
  # OpenNOW's jitter buffer can then stall and drop all audio for the rest of the
  # session. This wrapper raises the latency (override with OPENNOW_PW_LATENCY)
  # and names the stream "OpenNOW" so it can be identified/excluded in mixers.
  pwCatWrapper = pkgs: lib.hiPrio (pkgs.writeShellScriptBin "pw-cat" ''
    args=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --latency) args+=(--latency "''${OPENNOW_PW_LATENCY:-40ms}"); shift 2; continue ;;
        --latency=*) args+=("--latency=''${OPENNOW_PW_LATENCY:-40ms}") ;;
        *) args+=("$1") ;;
      esac
      shift
    done
    exec ${pkgs.pipewire}/bin/pw-cat \
      -P '{ application.name = "OpenNOW", node.description = "OpenNOW", media.name = "OpenNOW game audio" }' \
      "''${args[@]}"
  '');
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    libva
    libvdpau
    pipewire
    libpulseaudio
    libgpg-error # needed by the bundled libgcrypt
    (pwCatWrapper pkgs)
  ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/io.github.opencloudgaming.OpenNOW.desktop \
      $out/share/applications/io.github.opencloudgaming.OpenNOW.desktop
    substituteInPlace $out/share/applications/io.github.opencloudgaming.OpenNOW.desktop \
      --replace-fail 'Exec=opennow-qt' 'Exec=opennow'
    mkdir -p $out/share
    cp -r ${appimageContents}/usr/share/icons $out/share/
  '';

  meta = {
    description = "Open-source GeForce NOW client";
    homepage = "https://github.com/OpenCloudGaming/OpenNOW";
    license = lib.licenses.mit;
    platforms = builtins.attrNames sources;
    mainProgram = "opennow";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

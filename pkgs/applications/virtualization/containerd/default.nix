{ lib
, fetchFromGitHub
, buildGoPackage
, btrfs-progs
, go-md2man
, installShellFiles
, util-linux
, nixosTests
}:

buildGoPackage rec {
  pname = "containerd";
  version = "1.4.3";

  src = fetchFromGitHub {
    owner = "containerd";
    repo = "containerd";
    rev = "v${version}";
    sha256 = "09xvhjg5f8h90w1y94kqqnqzhbhd62dcdd9wb9sdqakisjk6zrl0";
  };

  goPackagePath = "github.com/containerd/containerd";
  outputs = [ "out" "man" ];

  nativeBuildInputs = [ go-md2man installShellFiles util-linux ];

  buildInputs = [ btrfs-progs ];

  buildFlags = [ "VERSION=v${version}" "REVISION=${src.rev}" ];

  BUILDTAGS = [ ]
    ++ lib.optional (btrfs-progs == null) "no_btrfs";

  buildPhase = ''
    cd go/src/${goPackagePath}
    patchShebangs .
    make binaries man $buildFlags
  '';

  installPhase = ''
    install -Dm555 bin/* -t $out/bin
    installManPage man/*.[1-9]
  '';

  # completion installed separately so it can be overridden in docker
  # can be moved to installPhase when docker uses containerd >= 1.4
  postInstall = ''
    installShellFiles --bash contrib/autocomplete/ctr
    installShellFiles --zsh --name _ctr contrib/autocomplete/zsh_autocomplete
  '';

  passthru.tests = { inherit (nixosTests) docker; };

  meta = with lib; {
    homepage = "https://containerd.io/";
    description = "A daemon to control runC";
    license = licenses.asl20;
    maintainers = with maintainers; [ offline vdemeester ];
    platforms = platforms.linux;
  };
}

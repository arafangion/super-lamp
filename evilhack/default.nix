let
  pkgs = import <nixpkgs> {};
  userDir = "~/.config/evilhack";
  binPath = with pkgs; lib.makeBinPath [ coreutils less ];
in pkgs.stdenv.mkDerivation {
  src = pkgs.fetchgit {
    url = "https://github.com/k21971/EvilHack";
    sha256 = "1fs7qdxqdzrdbg7rwv7ydrm0bxzdk7bcyx1yx8lggh31wgk425q1";
  };
  buildInputs = with pkgs; [
    which
    bash
    flex
    less
    bison
    ncurses
    gdb
    gnugrep
  ];
  name = "evilhack";
  gdbpath = pkgs.gdb;

  configurePhase = ''
    chmod -R +w .
    cp -v ${./sys_unix_hints_linux-debug} sys/unix/hints/linux-debug
    cp -v ${./sys_unix_sysconf} sys/unix/sysconf
    cp -v ${./sys_unix_Makefile.top} sys/unix/Makefile.top
    cp -v ${./util_Makefile} sys/unix/Makefile.utl
    cp -v ${./sys_unix_nethack.sh} sys/unix/nethack.sh
    pushd sys/unix
    sh setup.sh hints/linux-debug
    popd
  '';

  # Greately inspired by
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/games/nethack/default.nix
  postInstall = ''
      mkdir -p $out/bin
      cp ${./sys_unix_sysconf} $out/games/lib/evilhackdir/sysconf

      cat <<EOF >$out/bin/evilhack
      #! ${pkgs.stdenv.shell} -e
      PATH=${binPath}:\$PATH

      if [ ! -d ${userDir} ]; then
        mkdir -p ${userDir}
        cp -r $out/games/lib/evilhackdir/* ${userDir}
        chmod -R +w ${userDir}
      fi
        
      RUNDIR=\$(mktemp -d)
      cleanup() {
        rm -rf \$RUNDIR
      }
      trap cleanup EXIT
      cd \$RUNDIR
      for i in $out/games/lib/evilhackdir/*; do
        ln -s \$i \$(basename \$i)
      done
      $out/games/evilhack
      EOF
      chmod +x $out/bin/evilhack
      install -Dm 555 util/{makedefs,dgn_comp,lev_comp} -t $out/libexec/evilhack/
  '';
}

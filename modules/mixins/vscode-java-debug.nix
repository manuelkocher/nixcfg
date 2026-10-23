# vscode-java-debug.nix — vscjava.vscode-java-debug patched to work from the read-only Nix store.
#
# On activation the extension creates `.noConfigDebugAdapterEndpoints` inside its own
# install directory. In /nix/store that mkdir fails, activation aborts, and none of its
# commands get registered ("command 'java.debug.runJavaFile' not found").
# Put that directory in $XDG_RUNTIME_DIR instead (per jail in code-jail).
#
# Usage: (import ./vscode-java-debug.nix pkgs)
pkgs:

pkgs.vscode-extensions.vscjava.vscode-java-debug.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    substituteInPlace "$out/share/vscode/extensions/vscjava.vscode-java-debug/dist/extension.js" \
      --replace-fail 'o.join(t,".noConfigDebugAdapterEndpoints")' \
                     'o.join(process.env.XDG_RUNTIME_DIR||"/tmp","vscode-java-debug-endpoints")'
  '';
})

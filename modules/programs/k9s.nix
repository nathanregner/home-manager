{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.k9s;
  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = with maintainers; [
    katexochen
    liyangau
    hm.maintainers.LucasWagler
  ];

  imports = [
    (mkRenamedOptionModule [ "programs" "k9s" "skin" ] [
      "programs"
      "k9s"
      "skins"
      "skin"
    ])
  ];

  options.programs.k9s = {
    enable =
      mkEnableOption "k9s - Kubernetes CLI To Manage Your Clusters In Style";

    package = mkPackageOption pkgs "k9s" { };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/k9s/config.yaml`. See
        <https://k9scli.io/topics/config/> for supported values.
      '';
      example = literalExpression ''
        k9s = {
          refreshRate = 2;
        };
      '';
    };

    skins = mkOption {
      type = types.attrsOf yamlFormat.type;
      default = { };
      description = ''
        Skin files written to {file}`$XDG_CONFIG_HOME/k9s/skins/`. See
        <https://k9scli.io/topics/skins/> for supported values.
      '';
      example = literalExpression ''
        my_blue_skin = {
          k9s = {
            body = {
              fgColor = "dodgerblue";
            };
          };
        };
      '';
    };

    aliases = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Aliases written to {file}`$XDG_CONFIG_HOME/k9s/aliases.yaml`. See
        <https://k9scli.io/topics/aliases/> for supported values.
      '';
      example = literalExpression ''
        alias = {
          # Use pp as an alias for Pod
          pp = "v1/pods";
        };
      '';
    };

    hotkey = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Hotkeys written to {file}`$XDG_CONFIG_HOME/k9s/hotkey.yaml`. See
        <https://k9scli.io/topics/hotkeys/> for supported values.
      '';
      example = literalExpression ''
        hotkey = {
          # Make sure this is camel case
          hotKey = {
            shift-0 = {
              shortCut = "Shift-0";
              description = "Viewing pods";
              command = "pods";
            };
          };
        };
      '';
    };

    plugin = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Plugins written to {file}`$XDG_CONFIG_HOME/k9s/plugin.yaml`. See
        <https://k9scli.io/topics/plugins/> for supported values.
      '';
      example = literalExpression ''
        plugin = {
          # Defines a plugin to provide a `ctrl-l` shortcut to
          # tail the logs while in pod view.
          fred = {
            shortCut = "Ctrl-L";
            description = "Pod logs";
            scopes = [ "po" ];
            command = "kubectl";
            background = false;
            args = [
              "logs"
              "-f"
              "$NAME"
              "-n"
              "$NAMESPACE"
              "--context"
              "$CLUSTER"
            ];
          };
        };
      '';
    };

    views = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Resource column views written to {file}`$XDG_CONFIG_HOME/k9s/views.yaml`.
        See <https://k9scli.io/topics/columns/> for supported values.
      '';
      example = literalExpression ''
        k9s = {
          views = {
            "v1/pods" = {
              columns = [
                "AGE"
                "NAMESPACE"
                "NAME"
                "IP"
                "NODE"
                "STATUS"
                "READY"
              ];
            };
          };
        };
      '';
    };
  };

  config = let
    # darwin config dir changed in 0.25.4: https://github.com/derailed/k9s/pull/1322/files#diff-b335630551682c19a781afebcf4d07bf978fb1f8ac04c6bf87428ed5106870f5R283
    configDir = if (pkgs.stdenv.isDarwin
      && lib.versionAtLeast cfg.package.version "0.25.4") then
      "Library/Application Support/k9s"
    else
      "${config.xdg.configHome}/k9s";

    skinSetting = if (!(cfg.settings ? k9s.ui.skin) && cfg.skins != { }) then {
      k9s.ui.skin = "${builtins.elemAt (builtins.attrNames cfg.skins) 0}";
    } else
      { };

    skinFiles = mapAttrs' (name: value:
      nameValuePair "${configDir}/skins/${name}.yaml" {
        source = yamlFormat.generate "k9s-skin-${name}.yaml" value;
      }) cfg.skins;
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = {
      "${configDir}/config.yaml" = mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "k9s-config"
          (lib.recursiveUpdate skinSetting cfg.settings);
      };

      "${configDir}/aliases.yaml" = mkIf (cfg.aliases != { }) {
        source = yamlFormat.generate "k9s-aliases" cfg.aliases;
      };

      "${configDir}/hotkey.yaml" = mkIf (cfg.hotkey != { }) {
        source = yamlFormat.generate "k9s-hotkey" cfg.hotkey;
      };

      "${configDir}/plugin.yaml" = mkIf (cfg.plugin != { }) {
        source = yamlFormat.generate "k9s-plugin" cfg.plugin;
      };

      "${configDir}/views.yaml" = mkIf (cfg.views != { }) {
        source = yamlFormat.generate "k9s-views" cfg.views;
      };
    } // skinFiles;
  };
}

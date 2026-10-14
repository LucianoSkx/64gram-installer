# 64Gram — instalador para Linux

Instalador do [64Gram](https://github.com/TDesktop-x64/tdesktop) (Telegram Desktop não-oficial)
para qualquer distro Linux: **Debian, Ubuntu, Mint, Pop!_OS, Fedora, RHEL, Arch, CachyOS,
Manjaro, openSUSE, Void, Alpine** e derivados.

Baixa o pacote oficial do release do GitHub, verifica o checksum sha256, instala em
`/opt/64gram` (ou `~/.local`), cria o atalho do menu, os ícones e o handler de links `tg://`.

## Uso

```bash
chmod +x install.sh

./install.sh                     # instala no sistema (pede sudo)
./install.sh --user              # instala só para o usuário, sem root
./install.sh --version 1.2.10    # versão específica
./install.sh --local pacote.zip  # instala um zip já baixado (offline)
./install.sh --uninstall         # remove
```

Um-liner:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LucianoSkx/64gram-installer/main/install.sh) --user
```

## O que faz

| Item | Local (sistema) | Local (`--user`) |
|---|---|---|
| App | `/opt/64gram/` | `~/.local/share/64gram/` |
| Comando `64gram` | `/usr/local/bin/64gram` | `~/.local/bin/64gram` |
| Menu / ícones | `/usr/share/...` | `~/.local/...` |
| Conversas (`tdata`) | `~/.local/share/64Gram/` — **não são apagadas** ao remover | idem |

- Verifica o sha256 do pacote contra o checksum publicado no release do GitHub.
- Escreve `externalupdater.d` — desliga o atualizador interno do app; quem atualiza é este
  instalador (rode `./install.sh` de novo para atualizar).
- Avisa se faltar alguma biblioteca (`ldd`) e informa o comando de instalação da sua distro.
- Registra `tg://` via `MimeType=x-scheme-handler/tg`.
- Dependências de execução (verificadas com `ldd` no binário): glib2, pango, cairo,
  harfbuzz, freetype2, fontconfig, libx11/xcb/xext/xrender, libsystemd, libdbus.
  O Qt6 já vai embutido no binário do release — não precisa de Qt do sistema.

## Pacote Arch/CachyOS (PKGBUILD)

Em vez do script, em Arch/CachyOS dá para empacotar/instalar como pacote nativo:

```bash
cd packaging
makepkg -si          # gera e instala 64gram-<versão>.pkg.tar.zst
```

Quem preferir o AUR: `paru -S 64gram-desktop-bin` (pacote `64gram-desktop-bin`).

## Notas

- Testado em CachyOS (KDE/Wayland): instalação sistema e usuário, execução, remoção.
- O release do 64Gram é um zip portátil (`Telegram` + `Updater`); o instalador só coloca
  no lugar certo e integra com o sistema — nenhuma compilação.
- Conversas/contas ficam em `~/.local/share/64Gram` e sobrevivem a atualizações e remoções.

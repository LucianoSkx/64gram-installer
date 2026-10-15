<div align="center">

<img src="docs/assets/banner.png" alt="64Gram para Linux" width="880">

<p><b>64Gram no Linux — instale em um comando, sem compilar nada</b></p>

<p><sub>pacotes <b>.deb</b>, <b>.rpm</b> e <b>AppImage</b> gerados no GitHub a cada release do <a href="https://github.com/TDesktop-x64/tdesktop">64Gram</a></sub></p>

<br>

[![Release](https://img.shields.io/github/v/release/LucianoSkx/64gram-installer?style=flat-square&color=2AABEE&label=release)](https://github.com/LucianoSkx/64gram-installer/releases)
[![Downloads](https://img.shields.io/github/downloads/LucianoSkx/64gram-installer/total?style=flat-square&color=2AABEE&label=downloads)](https://github.com/LucianoSkx/64gram-installer/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/LucianoSkx/64gram-installer/packages.yml?style=flat-square&color=2AABEE&label=pacotes)](https://github.com/LucianoSkx/64gram-installer/actions/workflows/packages.yml)
[![License](https://img.shields.io/badge/license-GPL--3.0-2AABEE?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-2AABEE?style=flat-square)](#)

</div>

---

<div align="center">

<p><b>📦 Instalar / baixar</b></p>

<a href="https://github.com/LucianoSkx/64gram-installer/releases/latest"><img alt="ultima versao" src="https://img.shields.io/github/v/release/LucianoSkx/64gram-installer?style=for-the-badge&label=ultima%20versao&logo=telegram&logoColor=white"></a>
<a href="https://lucianoskx.github.io/64gram-installer/"><img alt="instalador" src="https://img.shields.io/badge/instalar-1_comando-2AABEE?style=for-the-badge&logo=gnubash&logoColor=white"></a>
<a href="https://github.com/LucianoSkx/64gram-installer/stargazers"><img alt="stars" src="https://img.shields.io/github/stars/LucianoSkx/64gram-installer?style=for-the-badge&logo=github&logoColor=white&color=2AABEE"></a>

<br>

</div>

---

<div align="center">

<p><b>🔗 Link único</b></p>

```bash
curl -fsSL https://lucianoskx.github.io/64gram-installer/install.sh | bash
```

<p><sub>funciona em fish, zsh, bash, dash e sh · com flags: <code>| bash -s -- --user</code> · ou copie em <a href="https://lucianoskx.github.io/64gram-installer/">lucianoskx.github.io</a></sub></p>

</div>

---

## ⚡ Instalação

<table>
<tr>
<td width="30%"><b>🐧 Debian · Ubuntu · Mint</b></td>
<td width="70%">

```bash
sudo apt install ./64gram_*_amd64.deb
```

</td>
</tr>
<tr>
<td><b>🎩 Fedora · RHEL · openSUSE</b></td>
<td>

```bash
sudo dnf install ./64gram-*.rpm
```

</td>
</tr>
<tr>
<td><b>📦 Qualquer distro (AppImage)</b></td>
<td>

```bash
chmod +x 64gram-*-x86_64.AppImage
./64gram-*-x86_64.AppImage
```

</td>
</tr>
</table>

<details open>
<summary><b>🗑️ Remover</b></summary>

<br>

```bash
curl -fsSL https://lucianoskx.github.io/64gram-installer/install.sh | bash -s -- --uninstall
```

Remove o app, o atalho, os ícones, o link **e as conversas** em
`~/.local/share/64Gram` — por isso ele pede confirmação.
Use `-y` para não perguntar (`| bash -s -- --uninstall -y`).

</details>

<details open>
<summary><b>📂 Se você já tem o arquivo</b></summary>

<br>

```bash
chmod +x install.sh
./install.sh --user
```

</details>

<details open>
<summary><b>🐧 Arch · CachyOS · Manjaro</b></summary>

<br>

O link único já instala pelo pacote certo — no Arch/CachyOS ele baixa o
`.pkg.tar.zst` e chama o `pacman -U`, que resolve as dependências sozinho.

```bash
# manualmente, a partir do .pkg.tar.zst da página:
sudo pacman -U 64gram-1.2.10-1-x86_64.pkg.tar.zst

# ou compilando o PKGBUILD deste repo:
cd packaging && makepkg -si
```

</details>

---

## 🎬 Como fica

<div align="center">
<img src="docs/assets/preview.png" alt="64Gram em execução" width="780">
</div>

---

## ✨ O que ele faz por você

- 📥 **Baixa e verifica** — pega o release oficial e confere o `sha256` antes de instalar
- 🖥️ **Instala em dois modos** — sistema (`/opt/64gram`, precisa de root) ou só para você (`~/.local`)
- 🧩 **Integra com o desktop** — ícones, menu, `tg://` e modo `--quit`
- 🔄 **Atualiza e remove limpo** — `install.sh` de novo atualiza; `--uninstall` remove tudo
- 💬 **Instalar não mexe nas conversas** — o `tdata` em `~/.local/share/64Gram` fica intacto ao instalar e atualizar
- 🤖 **Pacotes automáticos** — o GitHub gera `.deb`, `.rpm` e `.AppImage` a cada release novo

**Opções**

```bash
./install.sh --user              # instala só para o usuário, sem root
./install.sh --version 1.2.10    # versão específica
./install.sh --local pacote.zip  # instala um zip já baixado (offline)
./install.sh --uninstall         # remove
```

---

## 🏗️ Estrutura

```
install.sh                       instalador universal (bash puro)
.github/workflows/packages.yml   CI: .deb + .rpm + .AppImage
packaging/nfpm.yaml              fonte única dos pacotes deb/rpm
packaging/appimage/build.sh      AppImage: AppDir + mksquashfs + runtime
packaging/build-packages.sh      build local dos três formatos
packaging/PKGBUILD               pacote Arch/CachyOS
```

<details open>
<summary><b>Notas técnicas</b></summary>

<br>

- O release do 64Gram é um zip portátil (`Telegram` + `Updater`); o Qt6 já vai embutido
  no binário — as únicas dependências são glib2, pango, cairo, fontconfig, X11/xcb e
  dbus (checadas com `ldd`).
- O instalador escreve `externalupdater.d`, desligando o atualizador interno do app:
  quem atualiza é este script ou o seu gerenciador de pacotes.
- O CI consulta o release do upstream a cada 6h; se a tag `v<versão>` já existir aqui,
  não publica de novo.
- A AppImage é montada sem `appimagetool` (não precisa de FUSE no runner): `AppDir` +
  `mksquashfs` + runtime do AppImageKit.

</details>

---

<div align="center">
<sub>Projeto não-oficial · baseado no <a href="https://github.com/telegramdesktop/tdesktop">Telegram Desktop</a> · <a href="LICENSE">GPL-3.0</a></sub>
</div>

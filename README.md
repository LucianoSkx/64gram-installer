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

<p><sub>o script pergunta se quer instalar só para você ou no sistema — e já sugere a melhor opção para a sua máquina · funciona em fish, zsh, bash, dash e sh</sub></p>

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
curl -fsSL https://lucianoskx.github.io/64gram-installer/uninstall.sh | bash
```

Remove o app, o atalho, os ícones, o link **e as conversas** em
`~/.local/share/64Gram` — por isso ele pede confirmação.
Use `--yes` para não perguntar: `curl -fsSL https://lucianoskx.github.io/64gram-installer/uninstall.sh | bash -s -- --yes`.

</details>

<details open>
<summary><b>📂 Se você já tem o arquivo</b></summary>

<br>

```bash
chmod +x install.sh
./install.sh
```

</details>

<details open>
<summary><b>🐧 Arch · CachyOS · Manjaro</b></summary>

<br>

Se você preferir gerenciar pelo pacman, o pacote também está na página:

```bash
sudo pacman -U 64gram-1.2.10-1-x86_64.pkg.tar.zst
```

E dá para compilar o PKGBUILD deste repositório:

```bash
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
- 🔑 **Sem senha** — instala no seu usuário (`~/.local`), sem pedir root
- 🧩 **Integra com o desktop** — ícones, menu, `tg://` e modo `--quit`
- 🔄 **Atualiza e remove limpo** — `install.sh` de novo atualiza; `uninstall.sh` remove tudo
- 💬 **Instalar não mexe nas conversas** — o `tdata` em `~/.local/share/64Gram` fica intacto ao instalar e atualizar
- 🤖 **Pacotes automáticos** — o GitHub gera `.deb`, `.rpm`, `.pkg.tar.zst` e `.AppImage` a cada release novo

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

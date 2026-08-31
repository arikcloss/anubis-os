<div align="center">

<img src="https://github.com/user-attachments/assets/14a4ad1b-5c09-4f65-b186-6b246e2f88e3" width="140" alt="anubis-os logo" />

# anubis-os

**Uma imagem imutável baseada em Fedora Silverblue para quem quer tudo — sem abrir mão de nada.**

[![build](https://github.com/floatingskies/anubis-os/actions/workflows/build.yml/badge.svg)](https://github.com/floatingskies/anubis-os/actions/workflows/build.yml)
[![Fedora 44](https://img.shields.io/badge/Fedora-44-51a2da?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Base: Silverblue](https://img.shields.io/badge/Base-Silverblue_Main-3584e4?logo=gnome&logoColor=white)](https://silverblue.fedoraproject.org/)
[![Stars](https://img.shields.io/github/stars/floatingskies/anubis-os?style=social)](https://github.com/floatingskies/anubis-os/stargazers)

</div>

---

## O que é isso?

O **anubis-os** é uma imagem OCI customizada construída sobre o [Universal Blue](https://universal-blue.org/) — o mesmo projeto base do Bazzite e do Aurora. A ideia é simples: ter um sistema que joga, faz pentesting leve e mantém a máquina segura no dia a dia, tudo ao mesmo tempo, sem VMs, sem partições extras e sem quebrar nada.

O sistema base é atômico e imutável. O que você instala via Flatpak ou Brew fica separado do OS. Atualizações são transacionais — se algo der errado, você volta com um comando.

---

## Variantes

| Imagem | Para quem |
|--------|-----------|
| `anubis-os` | Hardware genérico x86_64 |
| `anubis-os-macbook` | MacBook Air Intel 2013–2017 (Wi-Fi Broadcom) |

---

## O que vem incluso

### 🕹️ Gaming

Pronto para jogar sem configurar nada. O Wine não está na imagem — tudo roda via Flatpak com Proton, o que mantém o sistema limpo.

| Pacote | Função |
|--------|--------|
| Steam (Flatpak) | Biblioteca + Proton |
| Lutris (Flatpak) | GOG, Epic, Battle.net |
| Dolphin, PPSSPP, PCSX2 | Emuladores |
| `gamemode` | Otimização de CPU/GPU automática |
| `gamescope` | Compositor dedicado para jogos |
| `mangohud` | Overlay de performance |

### 🔍 Pentesting leve

Ferramentas de rede e auditoria direto no terminal, sem quebrar as dependências do sistema operacional.

```
nmap  nmap-ncat  whois  curl  wget  traceroute  net-tools
```

Para ferramentas mais pesadas (`sqlmap`, `hydra`, `hashcat` etc.), a recomendação é usar um container via **Toolbox** ou **Distrobox** — assim você tem um ambiente dedicado e isolado sem contaminar a base.

### 🔒 Segurança diária

| Ferramenta | O que faz |
|------------|-----------|
| `firewalld` | Firewall com controle por zona |
| `firejail` | Sandboxing de aplicações |
| `clamav` | Antivírus |
| `rkhunter` + `aide` | Detecção de rootkits e alterações no sistema |

### 🎨 GNOME configurado de fábrica

Extensões ativas por padrão via dconf — sem ter que entrar no Extension Manager no primeiro boot.

- **Dash to Dock** — dock sempre visível
- **Blur my Shell** — fundo desfocado no launcher e no dash
- **PaperWM** — gerenciamento de janelas em scroll horizontal (ótimo para monitores ultrawide)
- **AppIndicator** — ícones de bandeja para apps como Discord e Telegram
- **Logo Menu** — menu de sistema com a logo do anubis-os
- **Caffeine** — impede o bloqueio de tela quando necessário

### 🛠️ Terminal

- **fastfetch** — informações do sistema ao abrir o terminal
- **Oh My Bash** — instalado no primeiro boot (sem precisar de internet na hora do rebase)
- **Starship** — prompt customizado, instalado via `curl | sh` no primeiro boot ou `brew install starship`
- **Homebrew** — gerenciador de pacotes para tudo que não está no rpm-ostree

---

## Instalação

### Rebase a partir de qualquer sistema Universal Blue ou Silverblue

```bash
# Imagem genérica
rpm-ostree rebase ostree-unverified-registry:ghcr.io/floatingskies/anubis-os:44

# Imagem para MacBook Air Intel 2013–2017
rpm-ostree rebase ostree-unverified-registry:ghcr.io/floatingskies/anubis-os-macbook:44
```

Reinicie após o rebase. No próximo boot, o sistema vai rodar o setup de primeiro uso (Oh My Bash, Starship, permissões).

### Verificar a assinatura da imagem

```bash
cosign verify ghcr.io/floatingskies/anubis-os \
  --certificate-identity-regexp=https://github.com/floatingskies \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

---

## Primeiro boot

O serviço `anubis-setup-user` roda automaticamente e:

1. Clona o **Oh My Bash** em `~/.oh-my-bash`
2. Instala o **Starship** em `~/.local/bin` via instalador oficial
3. Aplica o `.bashrc` e as configs de fastfetch e Starship

Se quiser rodar manualmente depois:

```bash
/usr/share/anubis-os/scripts/setup-ohmybash-user.sh
```

---

## Customização

### Adicionar pacotes ao sistema base

Edite `recipe.yml` (ou `recipe-macbook.yml`) e faça rebuild via GitHub Actions.

### Instalar algo pontualmente sem rebuild

```bash
# Persistente no sistema base (use com moderação)
rpm-ostree install <pacote>

# Via Homebrew (sem sudo, não toca no OS)
brew install <pacote>

# Via Flatpak (apps com sandbox)
flatpak install flathub <app-id>
```

### Ferramentas de pentesting num container isolado

```bash
# Criar um container Fedora com acesso à rede do host
distrobox create --name pentest --image fedora:latest
distrobox enter pentest
sudo dnf install nmap hydra sqlmap hashcat
```

---

## Estrutura do repositório

```
anubis-os/
├── recipes/
│   ├── recipe.yml              # imagem genérica
│   └── recipe-macbook.yml      # variante MacBook
├── files/
│   └── system/                 # arquivos copiados para / na imagem
│       ├── usr/share/backgrounds/anubis-os/
│       ├── usr/share/pixmaps/
│       └── usr/share/plymouth/themes/anubis/
└── scripts/
    ├── set-permissions.sh
    ├── setup-hostname.sh
    ├── setup-os-release.sh
    ├── setup-logo.sh
    ├── setup-plymouth.sh
    ├── setup-wallpaper.sh
    ├── setup-ohmybash.sh
    ├── enable-gnome-extensions-defaults.sh
    └── enable-first-boot-units.sh
```

---

## Build local

```bash
# Instalar o BlueBuild CLI
brew install blue-build/tap/bluebuild
# ou
cargo install blue-build

# Build
bluebuild build recipes/recipe.yml
```

---

## Contribuindo

Issues e PRs são bem-vindos. Se encontrou um Flatpak com ID errado, um script quebrando no build ou uma extensão com UUID desatualizado — abre uma issue.

---

<div align="center">

Feito com [Universal Blue](https://universal-blue.org/) · Baseado em [Fedora Silverblue](https://silverblue.fedoraproject.org/)

</div>

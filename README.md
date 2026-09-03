<div align="center">

<img src="https://github.com/user-attachments/assets/14a4ad1b-5c09-4f65-b186-6b246e2f88e3" width="140" alt="anubis-os logo" />

# anubis-os

**O Fedora mais limpo possível. GNOME minimalista, kernel Fedora, e nada que você não precise.**

[![build](https://github.com/arikcloss/anubis-os/actions/workflows/build.yml/badge.svg)](https://github.com/arikcloss/anubis-os/actions/workflows/build.yml)
[![iso](https://github.com/arikcloss/anubis-os/actions/workflows/iso.yml/badge.svg)](https://github.com/arikcloss/anubis-os/actions/workflows/iso.yml)
[![Fedora 44](https://img.shields.io/badge/Fedora-44-51a2da?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Base: Silverblue](https://img.shields.io/badge/Base-Silverblue_Main-3584e4?logo=gnome&logoColor=white)](https://silverblue.fedoraproject.org/)
[![Stars](https://img.shields.io/github/stars/arikcloss/anubis-os?style=social)](https://github.com/arikcloss/anubis-os/stargazers)

</div>

---

## O que é isso?

O **anubis-os** é uma imagem OCI imutável construída sobre [Universal Blue](https://universal-blue.org/) — o mesmo projeto base do Bazzite, Bluefin e Aurora. A ideia é ser o **sistema mais limpo possível** da base Fedora: GNOME, sim, mas sem nenhum app desnecessário.

### Filosofia

- **Minimal**: uma base GTK4 usável (Nautilus, Blackbox, Firefox, Htop, editor/terminal/calculadora, File Roller, LibreOffice) + GNOME Circle via Flatpak + Brew e ferramentas de cibersegurança. Nada de Maps, Weather, Calendar, Music, Photos, Videos, etc.
- **Performático**: kernel Fedora + tuned, irqbalance, zram — tudo pré-configurado para rodar bem em hardware antigo (1st-gen Intel Core), novo e modesto.
- **Estável**: cada script é idempotente, tem `set -euo pipefail` + trap de erro, e loga cada passo. A imagem e a ISO compartilham a mesma recipe — zero drift entre o que você testa no container e o que boota do ISO.
- **Harmonioso**: o build da imagem e o build da ISO são workflows separados mas encadeados. A ISO é gerada a partir da imagem já publicada, não da recipe diretamente.

---

## Hardware suportado

| Hardware | Como habilitar |
|----------|----------------|
| x86_64 genérico (1st-gen Intel Core → atual, todo AMD64) | Funciona out-of-the-box |
| MacBook Air/Pro Intel 2013–2017 (Broadcom Wi-Fi) | `ujust install-broadcom-wifi` + reboot |
| MacBook Air/Pro Intel 2013–2017 (FaceTime HD webcam) | `ujust install-facetimehd-webcam` + reboot |
| Outros laptops com Broadcom 43xx | `ujust install-broadcom-wifi` + reboot |

---

## O que vem incluso

### Aplicativos GUI (base GTK4 usável, instalados via RPM → funcionam offline)

| App | Função |
|-----|--------|
| **Nautilus** | Gerenciador de arquivos (GNOME Files) |
| **Blackbox-terminal** | Terminal emulator |
| **Firefox** | Navegador web |
| **Htop** | Monitor de processos |
| **GNOME Text Editor** | Editor de texto (GTK4) |
| **GNOME Console** | Terminal do GNOME (kgx) |
| **GNOME Calculator** | Calculadora |
| **File Roller** | Gerenciador de arquivos compactados |
| **LibreOffice** | Suíte de escritório |

Todos instalados como RPM no `/usr` — presentes de imediato, sem internet, no primeiro boot.

### GNOME Circle / produtividade (Flatpak, instalados no primeiro boot)

Estes apps não têm RPM no Fedora, então são gerenciados via `flatpak preinstall`
(declarados em `/usr/share/flatpak/preinstall.d/`): **Mission Center**,
**Gradio**, **Wike**, **Bazaar** (gerenciador de Flatpaks), **Amberol**,
**Obsidian**, **VSCodium**, **Eyedropper (conta-gotas)**, **Fragments**,
**Iotas**. Eles aparecem sozinhos logo após o primeiro boot, assim que a rede estiver disponível.

> **Nota técnica**: em imagem OSTree imutável, `/var/lib/flatpak` não é
> commitado na imagem, então Flatpaks não podem ser 100% embutidos offline —
> o service `anubis-flatpak-preinstall` instala automaticamente no primeiro
> boot, sem passo manual. O que precisa estar instantâneo/offline fica no RPM.

### Kernel & Performance

| Componente | O que faz |
|------------|-----------|
| **Kernel Fedora** | Kernel estável do Fedora (sem patches de terceiros) |
| **tuned + tuned-ppd** | Perfis adaptativos de performance/battery (integrado ao GNOME power settings) |
| **irqbalance** | Distribui IRQs entre CPUs para menor latência |
| **zram-generator** | Swap comprimido em RAM — o maior ganho de performance para hardware com 2-8 GB RAM |
| **gamemode** | Otimização de CPU/governor sob demanda |

### Ferramentas de Cibersegurança

Conjunto enxuto de ferramentas defensivas e de análise de rede, direto no RPM:

```
nmap  nmap-ncat  tcpdump  whois  traceroute  net-tools  bind-utils
firewalld  firejail  clamav  rkhunter  aide
git  vim  curl  wget  python3  python3-pip
```

Para ferramentas pesadas de pentesting (metasploit, hashcat, wireshark, hydra, sqlmap, etc.), use:

```bash
ujust install-pentest-tools
```

Isso cria um container Distrobox com o toolkit completo — a base imutável continua limpa.

### GNOME (minimal)

GNOME Shell + Control Center + GDM, com 4 extensões ativas por padrão:

- **Dash to Dock** — dock sempre visível
- **AppIndicator** — ícones de bandeja para apps como Discord, Telegram
- **Blur my Shell** — blur sutil no dash/overview (leve, GPU-friendly)
- **Caffeine** — inibe o screensaver sob demanda

### Terminal & Shell

- **Oh My Bash** — instalado no primeiro boot (via systemd service)
- **Starship** — prompt customizado, instalado no primeiro boot
- **fastfetch** — info do sistema ao abrir o terminal (com ASCII art do Anubis)
- **Homebrew** — gerenciador de pacotes user-space que não toca no OSTree

---

## Instalação

### Rebase a partir de qualquer sistema Universal Blue ou Silverblue

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/arikcloss/anubis-os:latest
```

Reinicie após o rebase. No próximo boot, o sistema roda o setup de primeiro uso (Oh My Bash, Starship, fastfetch config, wallpaper).

### Hardware com Broadcom Wi-Fi (MacBook 2013-2017, alguns Dell/HP)

```bash
ujust install-broadcom-wifi
systemctl reboot
```

### FaceTime HD Webcam (MacBook 2013-2017)

```bash
ujust install-facetimehd-webcam
systemctl reboot
```

### Instalação via ISO

Baixe a ISO da [página de Actions](https://github.com/arikcloss/anubis-os/actions/workflows/iso.yml) (artifact `iso-anubis-os`), grave em um pendrive com `dd` ou Ventoy, e boot.

A ISO instala o exato mesmo ostree image que o `rebase` puxaria — zero drift.

### Verificar a assinatura da imagem

```bash
cosign verify ghcr.io/arikcloss/anubis-os \
  --certificate-identity-regexp=https://github.com/arikcloss \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

---

## Estrutura do repositório

```
anubis-os/
├── recipes/
│   └── recipe.yml                 # imagem única (Fedora 44 + GNOME minimal)
├── files/
│   ├── scripts/                   # scripts de build-time (executados pelo BlueBuild)
│   │   ├── 00-debloat-gnome.sh    # remove apps padrão do GNOME (Calendar, Maps, etc.)
│   │   ├── setup-os-release.sh    # branding: /etc/os-release → "Anubis OS"
│   │   ├── setup-hostname.sh      # hostname → "anubis"
│   │   ├── setup-logo.sh          # substitui logos do Fedora pela logo Anubis
│   │   ├── setup-plymouth.sh      # tema de boot splash + rebuild do initramfs
│   │   ├── setup-wallpaper.sh     # remove wallpapers stock, instala coleção Anubis
│   │   ├── enable-gnome-extensions-defaults.sh  # configura dconf profile + compila DB
│   │   ├── setup-ohmybash.sh      # skeleton de .bashrc + first-boot script
│   │   ├── set-permissions.sh     # garante permissões corretas em todos os arquivos
│   │   └── enable-first-boot-units.sh  # habilita serviços de primeiro boot
│   └── system/                    # arquivos estáticos copiados para / na imagem
│       ├── etc/
│       │   ├── dconf/db/local.d/  # defaults do GNOME (extensões, wallpaper, GDM logo)
│       │   ├── sysctl.d/          # hardening do kernel
│       │   ├── profile.d/         # alias do fastfetch
│       │   ├── systemd/           # config do zram-generator
│       │   └── tuned/             # perfil tuned ativo
│       └── usr/
│           ├── lib/systemd/system/   # units de primeiro boot (5 serviços)
│           ├── lib/anubis-os/        # scripts de primeiro boot
│           ├── share/backgrounds/    # wallpapers Anubis
│           ├── share/flatpak/preinstall.d/  # apps GNOME Circle (flatpak preinstall)
│           ├── share/fastfetch/      # config + ASCII art
│           ├── share/pixmaps/        # logos
│           ├── share/icons/          # ícones hicolor
│           ├── share/ublue-os/just/  # comandos ujust customizados
│           └── share/applications/   # .desktop do "Update System"
├── .github/workflows/
│   ├── build.yml                 # build da imagem → GHCR
│   └── iso.yml                   # gera ISO da imagem publicada
├── cosign.pub                    # chave pública para verificação de assinatura
└── README.md
```

---

## Comandos ujust

O anubis-os inclui comandos customizados via `ujust`:

```bash
# Performance
ujust detect-cpu                 # identifica CPU
ujust set-tuned-profile          # troca perfil de performance

# Segurança
ujust enable-hardened-profile    # hardening agressivo (mitigations, nosmt, etc.)
ujust run-aide-check             # verifica integridade de arquivos
ujust run-rootkit-scan           # scan de rootkits
ujust install-pentest-tools      # toolkit pentesting em container Distrobox

# Desktop
ujust reroll-wallpaper           # troca o wallpaper aleatoriamente
ujust list-extensions            # lista extensões GNOME

# Gaming (opt-in — nada de gaming no base image)
ujust setup-gaming               # instala Steam + ProtonUp-Qt + Heroic via Flatpak

# Sistema
ujust update-all                 # atualiza tudo (rpm-ostree + flatpak + brew + fwupd)
ujust cleanup-flatpaks           # remove runtimes não utilizados
ujust roll-back                  # mostra deployments + como fazer rollback
ujust show-system-info           # fastfetch
```

---

## Build local

```bash
# Instalar o BlueBuild CLI
brew install blue-build/tap/bluebuild
# ou
cargo install blue-build

# Build da imagem
bluebuild build recipes/recipe.yml

# Gerar ISO da imagem já publicada
bluebuild generate-iso --output-dir iso-out \
  image ghcr.io/arikcloss/anubis-os:44
```

---

## Customização

### Adicionar pacotes ao sistema base

Edite `recipe.yml` e faça rebuild via GitHub Actions ou localmente.

### Instalar algo pontualmente sem rebuild

```bash
# Persistente no sistema base (use com moderação)
rpm-ostree install <pacote>

# Via Homebrew (sem sudo, não toca no OS)
brew install <pacote>

# Via Flatpak (apps com sandbox)
flatpak install flathub <app-id>
```

---

## Arquitetura de estabilidade

Cada script em `files/scripts/` segue estas regras:

1. **`set -euo pipefail`** — falha em qualquer erro, variável não definida, ou pipe quebrado.
2. **`trap '... ERR'`** — loga a linha exata onde o script falhou.
3. **Idempotente** — seguro rodar em todo build. Usa `cp -n`, `grep -q || echo`, `|| true` para operações não-críticas.
4. **Verificação de pré-requisitos** — checa se arquivos/diretórios existem antes de operar.
5. **Logging** — cada passo printa o que está fazendo com prefixo `[nome-do-script]`.
6. **Non-fatal warnings** — operações não-críticas falham com warning, não quebram o build.

O debloat do GNOME (`00-debloat-gnome.sh`) é especialmente robusto: filtra a apenas pacotes instalados e remove um por vez, então sobrevive a renames de pacotes entre versões do Fedora.

---

## Contribuindo

Issues e PRs são bem-vindos. Se encontrou um Flatpak com ID errado, um script quebrando no build ou uma extensão com UUID desatualizado — abre uma issue.

---

<div align="center">

Feito com [Universal Blue](https://universal-blue.org/) · Baseado em [Fedora Silverblue](https://silverblue.fedoraproject.org/)

</div>

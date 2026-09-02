<div align="center">

<img src="https://github.com/user-attachments/assets/14a4ad1b-5c09-4f65-b186-6b246e2f88e3" width="140" alt="anubis-os logo" />

# anubis-os

**O Fedora mais limpo possível. GNOME minimalista, kernel CachyOS, e nada que você não precise.**

[![build](https://github.com/floatingskies/anubis-os/actions/workflows/build.yml/badge.svg)](https://github.com/floatingskies/anubis-os/actions/workflows/build.yml)
[![iso](https://github.com/floatingskies/anubis-os/actions/workflows/iso.yml/badge.svg)](https://github.com/floatingskies/anubis-os/actions/workflows/iso.yml)
[![Fedora 44](https://img.shields.io/badge/Fedora-44-51a2da?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Base: Silverblue](https://img.shields.io/badge/Base-Silverblue_Main-3584e4?logo=gnome&logoColor=white)](https://silverblue.fedoraproject.org/)
[![Kernel: CachyOS](https://img.shields.io/badge/Kernel-CachyOS-8b5cf6?logo=linux&logoColor=white)](https://github.com/CachyOS/kernel-patches)
[![Stars](https://img.shields.io/github/stars/floatingskies/anubis-os?style=social)](https://github.com/floatingskies/anubis-os/stargazers)

</div>

---

## O que é isso?

O **anubis-os** é uma imagem OCI imutável construída sobre [Universal Blue](https://universal-blue.org/) — o mesmo projeto base do Bazzite, Bluefin e Aurora. A ideia é ser o **sistema mais limpo possível** da base Fedora: GNOME, sim, mas sem nenhum app desnecessário. Tipo um CachyOS do Fedora, mas com GNOME.

### Filosofia

- **Minimal**: só Nautilus, Blackbox-terminal, Firefox, Htop, Bazaar, Brew e ferramentas de cibersegurança. Nada de Maps, Weather, Calendar, Music, Photos, Videos, Calculator, etc.
- **Performático**: kernel CachyOS com patches de scheduler, scx-scheds (sched-ext), tuned, irqbalance, zram — tudo pré-configurado para rodar bem em hardware antigo (1st-gen Intel Core), novo e modesto.
- **Estável**: cada script é idempotente, tem `set -euo pipefail` + trap de erro, e loga cada passo. A imagem e a ISO compartilham a mesma recipe — zero drift entre o que você testa no container e o que boota do ISO.
- **Harmonioso**: o build da imagem e o build da ISO são workflows separados mas encadeados. A ISO é gerada a partir da imagem já publicada, não da recipe diretamente.

---

## Variantes

| Imagem | Para quem |
|--------|-----------|
| `anubis-os` | Hardware genérico x86_64 (1st-gen Intel Core → atual, todo AMD64) |
| `anubis-os-macbook` | MacBook Air/Pro Intel 2013–2017 (Broadcom Wi-Fi + FaceTime HD) |

---

## O que vem incluso

### Aplicativos GUI (4 apenas)

| App | Função |
|-----|--------|
| **Nautilus** | Gerenciador de arquivos (GNOME Files) |
| **Blackbox-terminal** | Terminal emulator |
| **Firefox** | Navegador web |
| **Htop** | Monitor de processos |
| **Bazaar** (Flatpak) | Gerenciador de Flatpaks |

Tudo o mais foi removido do base image via `rpm-ostree override remove`. O app grid do GNOME mostra só o que importa.

### Kernel & Performance

| Componente | O que faz |
|------------|-----------|
| **CachyOS kernel** | Kernel com patches de performance ( scheduler, CPU governor, BPF JIT hardening) |
| **scx-scheds** | Sched-ext schedulers (scx_bpfland, scx_lavd) — responsividade de desktop sob carga |
| **tuned + tuned-ppd** | Perfis adaptativos de performance/battery (integrado ao GNOME power settings) |
| **irqbalance** | Distribui IRQs entre CPUs para menor latência |
| **zram-generator** | Swap comprimido em RAM — o maior ganho de performance para hardware com 2-8 GB RAM |
| **gamemode** | Otimização de CPU/governor sob demanda |

### Ferramentas de Cibersegurança

Conjunto enxuto de ferramentas defensivas e de análise de rede, direto no RPM:

```
nmap  nmap-ncat  tcpdump  whois  traceroute  net-tools  bind-utils
firewalld  firejail  opensnitch  clamav  rkhunter  aide
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
# Imagem genérica
rpm-ostree rebase ostree-unverified-registry:ghcr.io/floatingskies/anubis-os:latest

# Imagem para MacBook Air/Pro Intel 2013–2017
rpm-ostree rebase ostree-unverified-registry:ghcr.io/floatingskies/anubis-os-macbook:latest
```

Reinicie após o rebase. No próximo boot, o sistema roda o setup de primeiro uso (Oh My Bash, Starship, fastfetch config, wallpaper).

### Instalação via ISO

Baixe a ISO da [página de Actions](https://github.com/floatingskies/anubis-os/actions/workflows/iso.yml) (artifact `iso-anubis-os` ou `iso-anubis-os-macbook`), grave em um pendrive com `dd` ou Ventoy, e boot.

A ISO instala o exato mesmo ostree image que o `rebase` puxaria — zero drift.

### Verificar a assinatura da imagem

```bash
cosign verify ghcr.io/floatingskies/anubis-os \
  --certificate-identity-regexp=https://github.com/floatingskies \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com

cosign verify ghcr.io/floatingskies/anubis-os-macbook \
  --certificate-identity-regexp=https://github.com/floatingskies \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

---

## Estrutura do repositório

```
anubis-os/
├── recipes/
│   ├── recipe.yml                # imagem genérica (Fedora 44 + GNOME minimal)
│   └── recipe-macbook.yml        # variante MacBook (Broadcom + FaceTime HD + TLP)
├── modules/                      # scripts de build-time (executados pelo BlueBuild)
│   ├── 00-debloat-gnome.sh       # remove apps padrão do GNOME (Calendar, Maps, etc.)
│   ├── setup-os-release.sh       # branding: /etc/os-release → "Anubis OS"
│   ├── setup-hostname.sh         # hostname → "anubis"
│   ├── setup-logo.sh             # substitui logos do Fedora pela logo Anubis
│   ├── setup-plymouth.sh         # tema de boot splash + rebuild do initramfs
│   ├── setup-wallpaper.sh        # remove wallpapers stock, instala coleção Anubis
│   ├── enable-gnome-extensions-defaults.sh  # configura dconf profile + compila DB
│   ├── setup-ohmybash.sh         # skeleton de .bashrc + first-boot script
│   ├── set-permissions.sh        # garante permissões corretas em todos os arquivos
│   └── enable-first-boot-units.sh  # habilita serviços de primeiro boot
├── files/system/                 # arquivos estáticos copiados para / na imagem
│   ├── etc/
│   │   ├── dconf/db/local.d/     # defaults do GNOME (extensões, wallpaper, GDM logo)
│   │   ├── sysctl.d/             # hardening do kernel
│   │   ├── profile.d/            # alias do fastfetch
│   │   ├── systemd/              # config do zram-generator
│   │   └── tuned/                # perfil tuned ativo
│   └── usr/
│       ├── lib/systemd/system/   # units de primeiro boot (3 serviços)
│       ├── lib/anubis-os/        # scripts de primeiro boot
│       ├── share/backgrounds/    # wallpapers Anubis
│       ├── share/fastfetch/      # config + ASCII art
│       ├── share/pixmaps/        # logos
│       ├── share/icons/          # ícones hicolor
│       ├── share/ublue-os/just/  # comandos ujust customizados
│       └── share/applications/   # .desktop do "Update System"
├── .github/workflows/
│   ├── build.yml                 # matrix build (anubis-os + macbook) → GHCR
│   └── iso.yml                   # gera ISO da imagem publicada
├── cosign.pub                    # chave pública para verificação de assinatura
└── README.md
```

---

## Comandos ujust

O anubis-os inclui comandos customizados via `ujust`:

```bash
# Performance
ujust detect-cpu                 # identifica CPU e sugere kernel otimizado
ujust switch-kernel-znver3       # AMD Zen 3 (Ryzen 5000)
ujust switch-kernel-znver4       # AMD Zen 4 (Ryzen 7000)
ujust enable-scx-scheduler       # ativa sched-ext (melhor responsividade)
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

# Build da imagem genérica
bluebuild build recipes/recipe.yml

# Build da variante MacBook
bluebuild build recipes/recipe-macbook.yml

# Gerar ISO da imagem já publicada
bluebuild generate-iso --output-dir iso-out \
  image ghcr.io/floatingskies/anubis-os:44
```

---

## Customização

### Adicionar pacotes ao sistema base

Edite `recipe.yml` (ou `recipe-macbook.yml`) e faça rebuild via GitHub Actions ou localmente.

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

Cada script no `modules/` segue estas regras:

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

Feito com [Universal Blue](https://universal-blue.org/) · Baseado em [Fedora Silverblue](https://silverblue.fedoraproject.org/) · Kernel [CachyOS](https://github.com/CachyOS/kernel-patches)

</div>

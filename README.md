# worktrunk 速查表 | worktrunk Cheatsheet | Guía rápida de worktrunk

> 一页看懂 Worktrunk：专为并行 AI agent 工作流设计的 Git worktree 管理 CLI。原生 git 建一个 worktree 要把分支名敲三遍、路径全靠手拼，它把 worktree 变成和分支一样顺手——按分支名寻址、路径按模板自动算。一个 agent 一个工位，谁也别踩谁的改动。想同时养 5 到 10 个 Claude Code / Codex，先把这一页看完。

- 上游项目：[max-sixty/worktrunk](https://github.com/max-sixty/worktrunk)（2026-11-05 实测 11,399 ★ / 430 forks / 153 releases，MIT OR Apache-2.0；根目录只有英文 README，文档站在 worktrunk.dev）
- 平台：macOS / Linux / Windows，单文件 CLI，命令名 `wt`（Windows 上另有 `git-wt`，见装法卡）
- 本页结构：中文主文 → English → Español → Português

---

Apoyo y más: [GitHub Sponsors](https://github.com/sponsors/Ezra-Zhao) · [Gumroad — plantillas y cuadernos que uso](https://ezraflow28.gumroad.com)

## 它是什么、不是什么

| 是 | 不是 |
|---|---|
| worktree 管理器：按分支名寻址，路径由可配置模板自动算出；命令能吃分支名，也能吃该分支所在 worktree 的路径 | 不是新的版本控制：底层还是 git worktree，仓库、分支、提交都是原生 git 的 |
| 为并行 agent 准备的：5-10 个 agent 各占一个工作目录，改动互不干扰 | 不是 agent 本身：它只管工位，不管 agent 干什么活 |
| 核心就三条命令，先学会切换、新建、清理，其余都是进阶 | 不是装完就能自动 cd：必须先跑 `wt config shell install` 装 shell 集成，见诚实标注区 |

## 核心三命令：对照原生 git 长命令

| 任务 | Worktrunk | 原生 git |
|---|---|---|
| 切换 worktree | `wt switch feat` | `cd ../repo.feat` |
| 新建并起 Claude | `wt switch -c -x claude feat` | `git worktree add -b feat ../repo.feat && cd ../repo.feat && claude` |
| 清理当前工位 | `wt remove` | `cd ../repo && git worktree remove ../repo.feat && git branch -d feat` |
| 带状态列表 | `wt list` | `git worktree list`（只有路径，没有状态） |

- `-c` 是 `--create` 的短写：`wt switch --create feature-auth` 从 main 新建分支和 worktree 并切过去。
- `-x` 是在切换之后执行后面的命令，所以 `-x claude` 就是切过去顺手把 Claude 起起来。
- 活干完两条路：PR 流就是 `wt step commit` 提交、`gh pr create` 开 PR、合并后回来 `wt remove`；本地合就用 `wt merge main`，见进阶四件。

## 并行多 agent：三行配方

每个新 worktree 里各起一个 agent，任务经 `--` 透传给 agent：

```bash
wt switch -x claude -c feature-a -- 'Add user authentication'
wt switch -x claude -c feature-b -- 'Fix the pagination bug'
wt switch -x claude -c feature-c -- 'Write tests for the API'
```

- `-x` 后面的命令在切换完成后运行，`--` 之后的参数原样传给它——上面就是给每个 Claude 的任务说明。
- 换成 Codex 同理：把 `claude` 换成 `codex` 即可，工位逻辑不变。
- 每个工位要先装依赖、起开发服务器，用 post-start hooks 自动办，见进阶四件。
- 可直接跑的版本在 [examples/parallel-agents.sh](examples/parallel-agents.sh)：三条分支、三个任务，改成你自己的就能用。

## wt list 状态符号读卡

`wt list` 的一行示例（上游快速上手原样结构）：

```text
  Branch        Status      HEAD±     main↕    main…±    Remote⇅  Commit    Age  Message
@ feature-auth  +   ↑      +27   -8   ↑1       +31                4bc72dc    2h  Add authenticatio…
^ main              ^⇡                                    ⇡1      0e631ad    1d  Initial commit
```

| 符号 | 意思 |
|---|---|
| `@` | 当前所在的 worktree |
| `+`（Status 列） | 有已暂存的改动（staged changes） |
| `↑1` | 领先 main 1 个提交（数字就是提交数） |
| `⇡` | 有未推送的提交（unpushed commits） |

其余列照字面读：`HEAD±` 是相对 HEAD 的增删行，`main↕` 是相对 main 的 ahead/behind，`Remote⇅` 是和远程的差距。想看每个分支的 CI 状态和 AI 生成摘要，再加一档：`wt list --full`。

## 进阶四件：一行版

| 功能 | 命令 / 做法 | 说明 |
|---|---|---|
| Hooks | 在配置里挂 create、pre-merge、post-merge 等时点的命令；post-start hooks 最常用 | 建完工位自动装依赖、起开发服务器，不用每个 agent 都交代一遍 |
| 本地合并 | `wt merge main` | 一条命令走完：生成提交信息并提交、squash、rebase 到 main、快进合并、清理工位 |
| 直跳 PR 分支 | `wt switch pr:123` | 按 PR 号直接切到那个 PR 的分支，不用先查分支名 |
| 构建缓存共享 | 共享 build caches（默认能力，文档站有专页） | 十个 worktree 共用 `target/`、`node_modules/` 这类缓存目录，不用各建一份、也不用复制——靠写时复制（copy-on-write），只支持 APFS、btrfs、XFS |

顺带两个：`wt list --full` 带 CI 状态与分支摘要；交互选择器能边刷 CI 状态边翻 diff、日志和 PR 预览，工位多了靠它找人。

## 装法卡：三平台一行版

所有平台装完都要跟一句 `wt config shell install`——shell 集成装上，`wt switch` 才能真的帮你切目录。

```bash
# Homebrew（macOS 与 Linux）
brew install worktrunk && wt config shell install

# Cargo
cargo install worktrunk && wt config shell install

# Arch Linux
sudo pacman -S worktrunk && wt config shell install

# Conda（社区维护的 feedstock）
conda install -c conda-forge worktrunk && wt config shell install
# 或 Pixi：pixi global install worktrunk && wt config shell install
```

Windows 单独看，这是最容易卡死人的一处：

```powershell
winget install max-sixty.worktrunk
git-wt config shell install
```

- Windows 上 `wt` 默认是 Windows Terminal 的命令，撞名了。所以 winget 装 Worktrunk 时会额外给它一个 `git-wt` 的名字避开冲突——在 Windows 上敲 `git-wt` 才是 Worktrunk，敲 `wt` 打开的是终端，不要以为装错了。
- 想直接用 `wt`，去 设置 → 应用 → 高级应用设置 → 应用执行别名，把「终端 / Terminal」「终端预览 / Terminal Preview」的别名关掉。

## 诚实标注区

- **shell 集成漏装是新用户第一坑**（上游 README 口径）：只装本体、不跑 `wt config shell install`，`wt switch` 就切不了目录，看起来像命令没生效。所有平台的装法都把这句写在同一行，先检查它再报 bug。
- **Windows 撞名不是装错**（上游 README 口径）：winget 给的是 `git-wt`，见装法卡；要么用 `git-wt`，要么关掉 Windows Terminal 的执行别名。
- **构建缓存共享有文件系统门槛**（上游文档口径）：copy-on-write 只在 APFS、btrfs、XFS 上成立，其他文件系统上别指望十个工位白嫖同一份缓存。
- **「最流行的 worktree 管理器」是原仓自述**（证据 B）：上游 2026 年 11 月自称已成最流行的 git worktree 管理器。数字这边只认实测的：11,399 星 / 430 forks / 153 releases（2026-11-05，证据 A）；153 个 release 的迭代密度说明它不是一阵风，但「最流行」没有第三方口径，就按自述标注。

---

## English (summary)

Worktrunk (11,399 stars / 430 forks / 153 releases as of 2026-11-05, MIT OR Apache-2.0) is a CLI for Git worktree management, designed for parallel AI agent workflows. Native git makes you type the branch name three times to start one worktree (`git worktree add -b feat ../repo.feat`, then `cd ../repo.feat`); Worktrunk addresses worktrees by branch name and computes paths from a configurable template, so worktrees feel like branches. Commands that take a branch also accept the path of the worktree it is checked out in.

The three core commands: `wt switch feat` switches worktrees (plain git: `cd ../repo.feat`); `wt switch -c -x claude feat` creates a worktree and starts Claude in it (plain git: add, cd, then launch); `wt remove` cleans up the current worktree and branch (plain git: cd back, `git worktree remove`, `git branch -d`). Add `wt list` for a status view plain `git worktree list` cannot give. For parallel agents, one line per agent, with the task passed through `--`: `wt switch -x claude -c feature-a -- 'Add user authentication'` — swap `claude` for `codex` to run Codex instead. In `wt list` output, `@` marks the current worktree, `+` means staged changes, `↑1` means 1 commit ahead of main, and `⇡` means unpushed commits; `wt list --full` adds CI status and AI-generated summaries per branch.

Going further: hooks run commands on create, pre-merge, post-merge and more (post-start hooks automate per-worktree setup such as installing dependencies and starting dev servers); `wt merge main` squashes, rebases onto main, fast-forward merges and cleans up in one command; `wt switch pr:123` jumps straight to a PR's branch; and build caches are shared across worktrees — ten worktrees get `target/`, `node_modules/` and similar directories without building or copying them, via copy-on-write on APFS, btrfs and XFS.

Install (every platform ends with the shell integration step): `brew install worktrunk && wt config shell install`; `cargo install worktrunk && wt config shell install`; on Arch, `sudo pacman -S worktrunk && wt config shell install`; with Conda, `conda install -c conda-forge worktrunk && wt config shell install` (or `pixi global install worktrunk`). On Windows, `wt` is Windows Terminal's command, so Winget additionally installs Worktrunk as `git-wt`: run `winget install max-sixty.worktrunk`, then `git-wt config shell install` — or disable the Terminal app execution alias to use `wt` directly. Honest notes: skipping `wt config shell install` is the first trap for new users, because without shell integration `wt switch` cannot change your directory; the shared build cache needs a copy-on-write filesystem (APFS, btrfs or XFS); and "the most popular git worktree manager" is the upstream repo's own claim (evidence level B) — the hard numbers above are the measured ones (evidence level A).

---

## Español (guía rápida — traducción de estudio, pendiente de revisión por un hablante nativo)

Worktrunk (11.399 estrellas / 430 forks / 153 releases a 5 de noviembre de 2026, MIT OR Apache-2.0) es una CLI para gestionar worktrees de Git, pensada para flujos con agentes de IA en paralelo. Con el git nativo, crear un worktree obliga a escribir el nombre de la rama tres veces (`git worktree add -b feat ../repo.feat` y luego `cd ../repo.feat`); Worktrunk direcciona los worktrees por nombre de rama y calcula las rutas desde una plantilla configurable, así que los worktrees se manejan como ramas. Los comandos que aceptan una rama también aceptan la ruta del worktree donde está esa rama.

Los tres comandos centrales: `wt switch feat` cambia de worktree (git nativo: `cd ../repo.feat`); `wt switch -c -x claude feat` crea el worktree y arranca Claude dentro (git nativo: add, cd y arrancar); `wt remove` limpia el worktree y la rama actuales (git nativo: volver, `git worktree remove`, `git branch -d`). Suma `wt list` para una vista con estado que `git worktree list` no da. Para agentes en paralelo, una línea por agente, con la tarea pasada tras `--`: `wt switch -x claude -c feature-a -- 'Add user authentication'` — cambia `claude` por `codex` para lanzar Codex. En la salida de `wt list`, `@` marca el worktree actual, `+` significa cambios en el área de preparación (staged), `↑1` significa 1 commit por delante de main y `⇡` significa commits sin empujar; `wt list --full` añade el estado de CI y resúmenes generados por IA por rama.

Un paso más: los hooks ejecutan comandos al crear, antes y después de fusionar, y en más momentos (los hooks post-start automatizan la preparación de cada worktree: instalar dependencias, arrancar servidores de desarrollo); `wt merge main` hace squash, rebase sobre main, fusión fast-forward y limpieza en un solo comando; `wt switch pr:123` salta directo a la rama de un PR; y las cachés de compilación se comparten entre worktrees — diez worktrees usan `target/`, `node_modules/` y directorios similares sin compilarlos ni copiarlos, con copy-on-write en APFS, btrfs y XFS.

Instalación (todas las plataformas terminan con el paso de integración de shell): `brew install worktrunk && wt config shell install`; `cargo install worktrunk && wt config shell install`; en Arch, `sudo pacman -S worktrunk && wt config shell install`; con Conda, `conda install -c conda-forge worktrunk && wt config shell install` (o `pixi global install worktrunk`). En Windows, `wt` es el comando de Windows Terminal, así que Winget instala Worktrunk además como `git-wt`: ejecuta `winget install max-sixty.worktrunk` y luego `git-wt config shell install` — o desactiva el alias de ejecución de Terminal para usar `wt` directamente. **Notas honestas**: saltarse `wt config shell install` es la primera trampa para quien empieza, porque sin la integración de shell `wt switch` no puede cambiar tu directorio; la caché compartida necesita un sistema de archivos con copy-on-write (APFS, btrfs o XFS); y «el gestor de worktrees más popular» es una afirmación del propio repositorio (evidencia nivel B) — las cifras duras de arriba son las medidas (evidencia nivel A).

---

## Português (guia rápido — tradução de estudo, aguardando revisão de um falante nativo)

Worktrunk (11.399 estrelas / 430 forks / 153 releases em 5 de novembro de 2026, MIT OR Apache-2.0) é uma CLI para gerenciar worktrees do Git, feita para fluxos com agentes de IA em paralelo. Com o git nativo, criar um worktree obriga a digitar o nome da branch três vezes (`git worktree add -b feat ../repo.feat` e depois `cd ../repo.feat`); o Worktrunk endereça os worktrees pelo nome da branch e calcula os caminhos a partir de um modelo configurável, então os worktrees se usam como branches. Os comandos que aceitam uma branch também aceitam o caminho do worktree em que ela está.

Os três comandos centrais: `wt switch feat` troca de worktree (git nativo: `cd ../repo.feat`); `wt switch -c -x claude feat` cria o worktree e inicia o Claude dentro dele (git nativo: add, cd e iniciar); `wt remove` limpa o worktree e a branch atuais (git nativo: voltar, `git worktree remove`, `git branch -d`). Some `wt list` para uma visão com status que `git worktree list` não entrega. Para agentes em paralelo, uma linha por agente, com a tarefa passada depois de `--`: `wt switch -x claude -c feature-a -- 'Add user authentication'` — troque `claude` por `codex` para rodar o Codex. Na saída do `wt list`, `@` marca o worktree atual, `+` significa alterações preparadas (staged), `↑1` significa 1 commit à frente da main e `⇡` significa commits não enviados; `wt list --full` adiciona o status de CI e resumos gerados por IA por branch.

Indo além: os hooks executam comandos ao criar, antes e depois do merge, e em mais momentos (os hooks post-start automatizam a preparação de cada worktree: instalar dependências, subir servidores de desenvolvimento); `wt merge main` faz squash, rebase sobre a main, merge fast-forward e limpeza em um único comando; `wt switch pr:123` pula direto para a branch de um PR; e os caches de build são compartilhados entre worktrees — dez worktrees usam `target/`, `node_modules/` e diretórios parecidos sem compilar nem copiar, com copy-on-write em APFS, btrfs e XFS.

Instalação (todas as plataformas terminam com o passo de integração de shell): `brew install worktrunk && wt config shell install`; `cargo install worktrunk && wt config shell install`; no Arch, `sudo pacman -S worktrunk && wt config shell install`; com Conda, `conda install -c conda-forge worktrunk && wt config shell install` (ou `pixi global install worktrunk`). No Windows, `wt` é o comando do Windows Terminal, então o Winget instala o Worktrunk adicionalmente como `git-wt`: rode `winget install max-sixty.worktrunk` e depois `git-wt config shell install` — ou desative o alias de execução do Terminal para usar `wt` direto. **Notas honestas**: pular o `wt config shell install` é a primeira armadilha de quem está começando, porque sem a integração de shell o `wt switch` não consegue mudar o seu diretório; o cache compartilhado precisa de um sistema de arquivos com copy-on-write (APFS, btrfs ou XFS); e «o gerenciador de worktrees mais popular» é uma afirmação do próprio repositório (evidência nível B) — os números duros acima são os medidos (evidência nível A).

---

## 来源与声明

- 灵感来源 / Source / Fuente / Fonte: [max-sixty/worktrunk](https://github.com/max-sixty/worktrunk)（文档站：[worktrunk.dev](https://worktrunk.dev)）
- 本仓是个人学习整理：内容用我自己的话总结自上游公开文档，不搬运原文；命令、装法与符号读法以 2026-11-05 的上游 README 与文档站为准，上游迭代后请以官方文档为最终依据。
- 西语、葡语部分为学习译稿，待母语校对。Las secciones en español y portugués son traducciones de estudio pendientes de revisión nativa.
- License: MIT © 2026 Guangyi Zhao

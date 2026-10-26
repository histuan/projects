<!-- Faithful copy of Thiago's personal dev-economico skill (Oct 2026), kept in Portuguese on purpose, for cloud sessions that do not have the skill. If the original in ~/.claude/skills changes, update this copy. -->

---
name: "dev-economico"
description: "Use SEMPRE que for criar, implementar, corrigir, refatorar, revisar ou planejar código com o Claude Code (apps, sites, scripts, jogos): regras de como ler, implementar, verificar, usar subagentes e conduzir a sessão gastando menos tokens sem perder qualidade."
---

# Desenvolvimento econômico com Claude Code

Objetivo: GASTAR MENOS sem a qualidade cair. Velocidade nunca justifica gastar mais. Na dúvida entre economizar e manter qualidade: manter qualidade e avisar em uma linha.

Plano Pro: chat, Claude Code e IDE gastam a MESMA cota (janela de 5 h + semanal).

## 0. Decisão rápida

```
Pedido chegou
 ├─ Ambíguo e caro de refazer? ──> perguntar ANTES (até 3 perguntas, cada uma com resposta sugerida: 1A, 2B…)
 ├─ Cabe em uma frase (1–2 arquivos)? ──> fazer direto, sem plano
 ├─ Grande/arriscado (vários módulos, dados, auth, migração, API pública)? ──> plano curto (≤ 40 linhas) → pessoa aprova → implementar
 └─ Grande e vago? ──> entrevistar → SPEC.md (arquivos, fora de escopo, verificação final) → implementar em sessão nova

Delegar a subagente?
 ├─ A saída é grande e a principal só precisa do resumo? ── sim ──> subagente (Haiku)
 └─ 1–2 leituras, 1 comando, ou a principal vai precisar do conteúdo? ──> fazer na principal
```

## 1. De onde vem o gasto

Cada mensagem e cada chamada de ferramenta reenviam a conversa inteira; o cache barateia, mas conta. Leitura/escrita de cache é a maior parte do custo. Escrever código é barato; caro é juntar contexto antes e verificar depois. Tokens de SAÍDA custam bem mais que os de entrada.
Multiplicadores: sessão longa, arquivo lido inteiro, saída longa de comando, imagens, idas e voltas, retrabalho, subagente desnecessário, esforço alto demais.

## 2. Antes de começar

- Se o pedido traz uma solução pronta para um problema não trivial, dizer em uma linha se existe saída mais simples antes de seguir.
- Definir o critério de pronto e COMO verificar (teste, build, lint, script) antes de codar.
- Projeto sem `.claude/agents/explorador-haiku.md` nem hook de filtro (nem em `~/.claude/`): sugerir UMA vez rodar `/dev-economico-setup`.

## 3. Ler e explorar barato

- Grep/Glob primeiro; Read só do trecho necessário (offset/limit) em arquivo grande.
- Não reler arquivo que já está no contexto e não mudou.
- Ignorar dependências, build e gerados (node_modules, dist, .next, venv, .godot, __pycache__…).
- Chamadas independentes (várias buscas/leituras) na MESMA mensagem, em paralelo: menos idas e voltas.
- Comandos com saída enxuta: flags quiet/silent, `--stat`, `head`/`tail`, `| tail -n 40`. Nunca `cat` de arquivo grande nem log inteiro.
- Investigação ampla: delegar ao explorador (seção 6) em vez de ler dezenas de arquivos na principal.
- Pesquisa com escopo: usar os arquivos/fontes que a pessoa indicou. Antes de ampliar (outras pastas, web, docs externas), dizer em uma linha o porquê. Parar de explorar assim que houver o suficiente para agir.

## 4. Implementar

- Arquivo existente: Edit pontual. Write só para arquivo novo ou reescrita realmente necessária (reescrever arquivo inteiro gasta saída).
- Escopo fechado: fazer SÓ o pedido. Nada de refatoração, feature ou "melhoria" não pedida; ideias extras vão em uma linha no relatório.
- Seguir o padrão existente do código; não introduzir dependência nova sem dizer por quê.
- Não colar código no chat nem repetir o plano de volta; citar `arquivo:linha`.
- Corrigir erro de compilação/tipo antes de rodar testes.

## 5. Verificar (qualidade não negociável)

- Bug: primeiro um teste (ou script) que reproduz; depois a correção.
- Feature nova com lógica testável: escrever primeiro os testes dos comportamentos principais, depois implementar (teste escrito depois tende a só confirmar o próprio código).
- Testar só o que importa: comportamento público e bordas relevantes. Não testar cada linha nem detalhe de implementação (incha o código e o gasto).
- Teste específico primeiro; suíte completa só no fim. Typecheck e lint (se o projeto tiver) antes de dar por pronto.
- Evidência, não afirmação: saída do comando, exit code, diff.
- Nunca enfraquecer/apagar teste, silenciar erro ou usar try/catch vazio para "passar". Causa raiz.
- Projeto sem testes: verificação mínima (build, executar e comparar saída, rodar headless). Ex. Godot: `godot --headless --check-only --script res://caminho.gd` para erros de parse.
- UI: preferir teste automatizado; screenshot só para conferir layout, uma imagem por vez.
- 2 tentativas falhas na mesma correção: PARAR e relatar hipóteses + o que testar, em vez de insistir.
- Não reconferir o que um teste já confirmou.
- Revisão extra só com risco alto (segurança, dados, mudança grande): `/code-review` ou revisor em contexto novo pedindo "só lacunas de corretude ou dos requisitos".

## 6. Subagentes

- Usar SÓ quando DIMINUIR o gasto total. Paralelo só se o total não aumentar (muitas tentativas baratas e fáceis de checar); nunca por velocidade.
- Subagente começa do zero (recarrega instruções, cache de 5 min). Não compensa para 1–2 leituras, 1 comando, ou quando a principal vai precisar do conteúdo inteiro.
- Modelo:
  - **explorador-haiku**: busca mecânica (onde X está, listar, ler configs). Usar no lugar do Explore embutido, que roda no modelo principal.
  - **verificador-haiku**: vários comandos ou saída longa que o hook não filtra. 1 comando filtrado: rodar na principal.
  - Pesquisa analítica (mapear arquitetura, escopo de mudança): Sonnet é opção a testar; na dúvida, principal.
  - Implementação e decisões: sempre na principal. Se o subagente travar, a principal assume.
- Briefing: objetivo, pastas, o que devolver, limite (≤ 15–25 linhas, `arquivo:linha`). Sem histórico da conversa.

## 7. Fechar a tarefa

Relatório final (≤ 25 linhas), sempre neste formato:
1. O que mudou: `git diff --stat`
2. Verificação: comando(s) + resultado (só falhas/avisos, se houver)
3. Decisões que tomei sozinho
4. Como a pessoa testa (passos curtos)
5. Ideias fora do escopo (opcional, 1–3 linhas)

Depois, uma linha: "Tarefa fechada; vale `/clear` antes da próxima."
Tarefa longa que não terminou e contexto já grande (muitos arquivos/saídas lidos, ou `/context` acima de ~150 mil tokens; a qualidade começa a cair entre 100 e 200 mil): escrever `ESTADO.md` (fora do git; ≤ 30 linhas: objetivo, feito, falta, decisões, comandos de verificação) e sugerir `/clear` + "continue a partir do ESTADO.md". É mais barato e confiável que `/compact`.

## 8. Lembretes para a pessoa (uma linha, só no momento certo)

- 2 correções falhas no mesmo ponto → `/clear` + pedido melhor.
- Caminho errado → `/rewind` (Esc Esc), mais barato que `/compact`.
- Pergunta lateral → `/btw` (não entra no histórico).
- Pausa > 1 h → cache expira; fechar a tarefa antes.
- Esforço: `medium` padrão; `high`/`xhigh` só se travar (nos 5.5 trocar esforço não quebra cache); evitar `low`; NUNCA `max`.
- Trocar de modelo no meio custa uma resposta sem cache: escolher no início (padrão Opus).
- Perto do limite de 5 h: fechar o que dá, escrever `ESTADO.md`, retomar depois do reset.
- Auto-compact disparou no meio da tarefa → melhor `ESTADO.md` + sessão nova do que seguir na sessão compactada.
- Comando simples que a pessoa só quer ver (status, rodar o jogo, um teste) → ela mesma digita `!comando`; a saída entra no contexto sem o modelo gastar uma volta decidindo.
- Descrever pedido grande → `/voice` ajuda a dar detalhe sem esforço.
- `/loop`, `/goal` e tarefas agendadas: cada execução reenvia o contexto. No Pro, só com tarefa curta, sessão limpa e intervalo longo.
- Medir de vez em quando: `/usage` (tecla `f` aplica recomendações), `/context`, `/insights`.

## 9. Manutenção de instruções

- `CLAUDE.md` do projeto < 200 linhas: comandos de build/teste/lint, convenções fora do padrão, armadilhas. Fora: o que se deduz do código, tutoriais, descrição arquivo por arquivo. Nunca `@` de arquivo grande (import não economiza).
- `~/.claude/CLAUDE.md` global soma com o do projeto; não repetir. Exceção: escrever explicitamente no do projeto.
- Seções úteis no CLAUDE.md do projeto: "Estado atual" (≤ 5 linhas, atualizar ao fechar marcos) e "Manias a evitar" (o que a IA errou e a pessoa corrigiu, ex.: texto de interface em CAIXA ALTA).
- Instrução que a pessoa repetiu 2+ vezes → propor linha no CLAUDE.md ou skill (mostrar antes de gravar).
- Pastas que nunca devem ser lidas: regras `Read` em `permissions.deny` (`.claudeignore` não tem efeito).
- Workflow ocasional → skill; skill que só a pessoa chama → `disable-model-invocation: true`.
- CLI antes de MCP (`gh` etc.); desligar MCP/plugin sem uso; linguagem tipada → plugin de code intelligence.
- Auditoria periódica: `/doctor prompt-audit`.

## 10. Chat (claude.ai, quando usado junto)

- Ler código nesta ordem: relatório do Claude Code → `git diff -- <arquivo>` colado → ferramentas do PC só se inevitável (um comando filtrado, nunca arquivo inteiro) → GitHub só para histórico já enviado.
- Respostas curtas; não repetir planos.
- Chat novo a cada fase; antes, salvar o estado enxuto na memória do projeto.
- Sonnet para rotina; Opus só para decisão difícil.

## 11. Commits

Só quando a pessoa pedir (salvo combinado diferente). Seguir a convenção do projeto e as regras dela; perguntar se não houver.

## 12. Modo aprendizado (só quando a pessoa pedir)

A pessoa é estudante. Quando ela disser "modo aprendizado" (ou for projeto de estudo e ela pedir para entender):
- No relatório, para cada mudança relevante: o que mudou, POR QUE assim, e a alternativa descartada (1–3 linhas cada).
- Apontar um trecho que vale ela ler com atenção.
- Não alongar o resto do relatório. Fora desse modo, manter o relatório curto da seção 7.

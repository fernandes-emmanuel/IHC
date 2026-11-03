# Relatório — Lab IHC: Sistema de Autenticação com IA Generativa

**Universidade Federal de Goiás — Instituto de Informática**
**Disciplina:** IHC – Interação Humano-Computador — Prof. Dirson S. Campos
**Grupo:** _(preencher)_ — **Integrantes:** _(preencher)_
**IA generativa usada:** Claude (Anthropic), via Claude Code

---

## 1. Objetivo
Gerar, com o auxílio de uma IA generativa, o protótipo front-end (HTML, CSS e JavaScript) de uma tela de autenticação que mantenha o **mesmo design de interface e a mesma usabilidade** do sistema legado apresentado nas figuras do enunciado. O protótipo roda localmente no VS Code com o Live Server (`http://127.0.0.1:5500/index.html`).

## 2. Metodologia
1. **Requisitos da UI** extraídos das figuras do enunciado (telas, textos, campos, ícones, transição e balões de validação).
2. **Ferramenta:** Claude (Anthropic). O arquivo `CLAUDE.md` na raiz guarda as instruções permanentes do projeto.
3. **Prompt:** o PDF do enunciado foi anexado junto com o prompt da seção 3.
4. **Geração:** a IA gerou `index.html`, `style.css` e `script.js` na pasta `autenticacao/`.
5. **Execução e verificação:** o protótipo foi aberto no navegador (Chromium) em desktop (1280×720) e celular (390×844), e cada requisito foi conferido (seção 5).

## 3. Prompts utilizados

**Prompt 1** (com o PDF do enunciado anexado):
> Crie a estrutura mínima necessária e simples para resolver essa tarefa com maestria, cumprindo todos os requisitos. A parte visual pode humilhar, faça o frontend mais bonito possível, com animações, paralax, liquid glass e etc.

_(Se o grupo fizer novos pedidos de ajuste, registrar aqui como Prompt 2, 3, …)_

## 4. Ajustes feitos durante a geração
Durante a verificação no navegador, a própria IA encontrou e corrigiu estes problemas:

| # | Problema encontrado | Correção |
|---|---|---|
| 1 | A animação de entrada do card fixava o `transform` e travava a inclinação 3D. | `animation-fill-mode` mudou de `both` para `backwards`. |
| 2 | Com o card transparente (vidro), os dois formulários apareciam sobrepostos. | O formulário inativo recebe `opacity: 0` e `visibility: hidden`, com a troca feita enquanto o painel azul cobre o card. |
| 3 | "Bem-vindo de volta!" quebrava em duas linhas, diferente do legado. | Ajuste do `padding` do painel e da fonte do título (34px). |
| 4 | Clicar ou focar um botão fora da área visível rolava o conteúdo do card e deslocava o layout. | `overflow: clip` no card e `inert` no painel que está fora da tela. |
| 5 | Em telas pequenas, os formulários não animavam na vertical. | Inclusão de `bottom` na transição dentro do `@media (max-width: 650px)`. |

**Alterações manuais:** _(o grupo deve descrever aqui o que mudou à mão, por exemplo: troca de "Grupo X" pelo nome do grupo em `index.html`)_.

## 5. Resultados — verificação dos requisitos

| Requisito do enunciado | Implementação | OK |
|---|---|---|
| Arquivos `index.html`, `style.css`, `script.js` | Pasta `autenticacao/` | ✅ |
| Tela **Autenticação**: Username, Password, "Esqueceu a Senha?", Login | `form#loginForm` com ícones de usuário e cadeado | ✅ |
| Painel azul curvo "Bem-vindo a solução do Grupo X!" + "Cadastre-se" | `.toggle-box::before` (border-radius 150px, `#7494ec`) | ✅ |
| Transição em ms ao clicar Cadastre-se (o painel cobre o card) | `--t-slide: 1800ms`, `--t-swap: 600ms`, `--t-delay: 1200ms` | ✅ |
| Tela **Inscreva-se**: Username, Email, Password, Cadastre-se + "Bem-vindo de volta!" | `form#registerForm` e `.toggle-right` | ✅ |
| Login no painel volta para Autenticação | `setScreen(false)` em `script.js` | ✅ |
| Validação Username/Password vazios ("Preencha este campo.") | Atributo `required` (balão nativo) | ✅ |
| Validação Username/Email/Password no cadastro | `required` + `type="email"` ("Inclua um "@"…") | ✅ |
| Adaptação a tamanhos de tela | `@media (max-width: 650px)`: o painel desliza na vertical | ✅ |
| Somente front-end (sem back-end/BD) | Envio simulado com mensagem (toast); nada é salvo | ✅ |

**Melhorias visuais (sem mudar o layout nem o fluxo do legado):** card em *liquid glass* (`backdrop-filter`), fundo com formas que se deformam e orbes de vidro em **paralaxe** de três camadas, inclinação 3D e reflexo que seguem o mouse, botão com brilho e efeito *ripple*, campo que treme quando é inválido, estado de carregamento no envio, mensagem de confirmação (toast) e respeito a `prefers-reduced-motion`.

### Capturas de tela (`docs/capturas/`)
| Arquivo | Tela |
|---|---|
| `01-login.png` | Tela de Autenticação |
| `02-transicao.png` | Transição: o painel azul cobre o card |
| `03-cadastro.png` | Tela Inscreva-se |
| `04-cadastro-ok.png` | Cadastro simulado com sucesso (toast) |
| `05-volta-login.png` | Volta para Autenticação com o username preenchido |
| `06-mobile-login.png` / `07-mobile-cadastro.png` | Versão para celular |

> Os balões nativos de validação ("Preencha este campo.") não aparecem em capturas automáticas. O grupo deve capturá-los manualmente no navegador (Print Screen), como nas figuras do enunciado. O texto do balão segue o idioma do navegador: em português, aparece igual às figuras.

## 6. Conclusão
A IA generativa produziu, a partir das figuras do enunciado e de um único prompt, um protótipo funcional que reproduz a estrutura, os textos, o fluxo de telas e as validações do sistema legado. Ela também encontrou e corrigiu sozinha os defeitos que surgiram ao testar no navegador.

**Dificuldades:** ao usar fundo transparente (vidro) foi preciso esconder o formulário inativo, porque o legado depende de fundo branco opaco. As animações 3D exigiram cuidado com o recorte (`overflow`) e com a rolagem interna do card.

**Limitações:** não há autenticação real nem persistência de dados (fora do escopo do lab). O `backdrop-filter` depende do navegador e, onde não existe, o card fica branco translúcido. Os textos dos balões de validação dependem do idioma do navegador.

## 7. Como reproduzir
1. Usar o mesmo prompt da seção 3 no Claude, anexando o PDF do enunciado.
2. Abrir a pasta `autenticacao/` no VS Code e iniciar o Live Server.
3. Conferir os itens da tabela da seção 5.

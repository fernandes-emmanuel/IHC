# CLAUDE.md

Instruções permanentes para o Claude neste repositório.

## Projeto
Protótipo **front-end** de uma tela de autenticação (Login + Cadastro) para o Lab de IHC (UFG / INF, Prof. Dirson S. Campos).
Objetivo: reproduzir o **mesmo design e a mesma usabilidade** do sistema legado do professor, com acabamento visual moderno (liquid glass, paralaxe, micro-animações).

## Stack e estrutura
Somente HTML, CSS e JavaScript puro. Sem frameworks, sem build, sem back-end, sem banco de dados.

```
autenticacao/
├── index.html   # estrutura (2 formulários + painel deslizante)
├── style.css    # visual, transições e responsividade
└── script.js    # troca de tela, feedback de validação, envio simulado, paralaxe
```

## Como executar
Abrir `autenticacao/` no VS Code → botão direito em `index.html` → **Open with Live Server** → `http://127.0.0.1:5500/index.html`.
Também funciona abrindo o `index.html` direto no navegador.

## Requisitos que NÃO podem quebrar
1. Card centralizado (~850×550) com painel azul `#7494ec` curvo (border-radius 150px) e fonte Poppins.
2. Tela inicial: painel à esquerda ("Bem-vindo a solução do Grupo X!", "Sem conta? Cadastre-se agora!", botão **Cadastre-se**) e formulário **Autenticação** à direita (Username, Password, "Esqueceu a Senha?", **Login**).
3. Ao clicar **Cadastre-se**: o painel azul cobre todo o card e, ao final, fica à direita ("Bem-vindo de volta!", "Já tem uma conta?", **Login**) com o formulário **Inscreva-se** à esquerda (Username, Email, Password, **Cadastre-se**).
4. Ao clicar **Login** no painel: transição inversa até a tela de Autenticação.
5. Tempos da transição em ms definidos em `:root` no CSS: `--t-slide: 1800ms`, `--t-swap: 600ms`, `--t-delay: 1200ms`.
6. Validação **nativa** do navegador (`required` e `type="email"`), que mostra os balões "Preencha este campo." e "Inclua um "@" no endereço de e-mail…". Não usar `novalidate`.
7. Responsivo: em telas ≤ 650px o painel desliza na vertical (topo ↔ base).

## Convenções
- Textos da interface em pt-BR, idênticos ao legado.
- Cores e tempos sempre via variáveis CSS em `:root`.
- Ícones em SVG inline (sem dependência de CDN de ícones).
- Mensagens dinâmicas sempre com `textContent` (nunca `innerHTML` com dado do usuário).
- Respeitar `prefers-reduced-motion`.
- O nome do grupo fica em `<span class="group-name">` no `index.html` e no `<title>`: trocar "Grupo X" pelo nome do grupo.

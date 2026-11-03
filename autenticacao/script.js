/* =========================================================
   Sistema de Autenticação — interações do protótipo
   (front-end apenas: nenhuma credencial é enviada/armazenada)
   ========================================================= */

const container   = document.getElementById("container");
const registerBtn = document.querySelector(".register-btn");
const loginBtn    = document.querySelector(".login-btn");
const loginForm   = document.getElementById("loginForm");
const registerForm = document.getElementById("registerForm");
const toastEl     = document.getElementById("toast");

const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const finePointer  = window.matchMedia("(pointer: fine)").matches;

/* ---------- 1. Transição entre telas (painel deslizante) ---------- */
const panelLeft  = document.querySelector(".toggle-left");
const panelRight = document.querySelector(".toggle-right");

function setScreen(register) {
  container.classList.toggle("active", register);
  // O painel que está fora da área visível não recebe foco pelo teclado
  panelLeft.inert = register;
  panelRight.inert = !register;
}
setScreen(false);

registerBtn.addEventListener("click", () => setScreen(true));
loginBtn.addEventListener("click", () => setScreen(false));

/* ---------- 2. Validação dos TextBoxes ----------
   A validação usa os atributos nativos `required` e `type="email"`,
   gerando os balões do navegador ("Preencha este campo.",
   "Inclua um "@" no endereço de e-mail...") iguais ao legado.
   Aqui só adicionamos o feedback visual (tremida + borda). */
document.querySelectorAll("form").forEach((form) => {
  form.addEventListener("invalid", (e) => {
    const box = e.target.closest(".input-box");
    if (!box) return;
    box.classList.remove("shake");
    void box.offsetWidth;            // reinicia a animação
    box.classList.add("shake");
  }, true);
});

document.querySelectorAll(".input-box").forEach((box) =>
  box.addEventListener("animationend", () => box.classList.remove("shake"))
);

/* ---------- 3. Envio simulado (só ocorre se todos os campos forem válidos) ---------- */
function simulate(form, onDone) {
  const btn = form.querySelector("button[type=submit]");
  btn.classList.add("loading");
  btn.disabled = true;
  setTimeout(() => {
    btn.classList.remove("loading");
    btn.disabled = false;
    onDone();
  }, 900);
}

loginForm.addEventListener("submit", (e) => {
  e.preventDefault();
  const user = loginForm.username.value.trim();
  simulate(loginForm, () => {
    showToast(`Login realizado com sucesso. Bem-vindo, ${user}!`);
    loginForm.reset();
  });
});

registerForm.addEventListener("submit", (e) => {
  e.preventDefault();
  const user = registerForm.username.value.trim();
  simulate(registerForm, () => {
    showToast(`Cadastro de ${user} realizado! Faça login.`);
    registerForm.reset();
    setScreen(false);
    loginForm.username.value = user;
  });
});

document.getElementById("forgotLink").addEventListener("click", (e) => {
  e.preventDefault();
  showToast("Link de recuperação enviado (simulação).", "✉");
});

/* ---------- 4. Toast ---------- */
let toastTimer;
function showToast(message, icon = "✓") {
  toastEl.innerHTML = "";
  const dot = document.createElement("span");
  dot.className = "dot";
  dot.textContent = icon;
  const text = document.createElement("span");
  text.textContent = message;           // textContent evita injeção de HTML
  toastEl.append(dot, text);
  toastEl.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toastEl.classList.remove("show"), 3200);
}

/* ---------- 5. Efeito ripple nos botões ---------- */
document.querySelectorAll(".btn").forEach((btn) => {
  btn.addEventListener("pointerdown", (e) => {
    const r = btn.getBoundingClientRect();
    const size = Math.max(r.width, r.height);
    const span = document.createElement("span");
    span.className = "ripple";
    span.style.width = span.style.height = `${size}px`;
    span.style.left = `${e.clientX - r.left - size / 2}px`;
    span.style.top  = `${e.clientY - r.top - size / 2}px`;
    btn.appendChild(span);
    span.addEventListener("animationend", () => span.remove());
  });
});

/* ---------- 6. Paralaxe + inclinação 3D + reflexo do vidro ---------- */
if (!reduceMotion && finePointer) {
  const layers = [...document.querySelectorAll(".layer")];
  const panels = [...document.querySelectorAll(".toggle-panel")];
  const target = { x: 0, y: 0 };
  const current = { x: 0, y: 0 };

  window.addEventListener("pointermove", (e) => {
    target.x = (e.clientX / innerWidth) * 2 - 1;   // -1 … 1
    target.y = (e.clientY / innerHeight) * 2 - 1;

    const r = container.getBoundingClientRect();
    container.style.setProperty("--mx", `${e.clientX - r.left}px`);
    container.style.setProperty("--my", `${e.clientY - r.top}px`);
  });

  document.addEventListener("pointerleave", () => { target.x = 0; target.y = 0; });

  (function loop() {
    current.x += (target.x - current.x) * 0.08;    // suavização (lerp)
    current.y += (target.y - current.y) * 0.08;

    layers.forEach((layer) => {
      const d = Number(layer.dataset.depth);
      layer.style.transform = `translate3d(${-current.x * d}px, ${-current.y * d}px, 0)`;
    });

    container.style.setProperty("--ry", `${current.x * 4}deg`);
    container.style.setProperty("--rx", `${-current.y * 4}deg`);

    panels.forEach((p) => {
      p.style.setProperty("--px", `${current.x * 10}px`);
      p.style.setProperty("--py", `${current.y * 8}px`);
    });

    requestAnimationFrame(loop);
  })();
}

import { API_URL } from "./config.js";
import { api } from "./api.js";

const $ = (selector, root = document) => root.querySelector(selector);

$("#docs-link").href = API_URL;

const dateFormat = new Intl.DateTimeFormat("fr-FR", { dateStyle: "long" });
const formatDate = (iso) => dateFormat.format(new Date(iso));

// Construit un élément sans jamais passer par innerHTML : les données de
// l'API (titres, noms) sont insérées comme du texte.
function el(tag, props = {}, ...children) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(props)) {
    if (key === "class") node.className = value;
    else if (key.startsWith("on")) node.addEventListener(key.slice(2), value);
    else node.setAttribute(key, value);
  }
  node.append(...children);
  return node;
}

function button(label, onClick, className = "") {
  return el("button", { type: "button", class: className, onclick: onClick }, label);
}

function toast(message, isError = false) {
  const node = el("p", { class: isError ? "toast error" : "toast" }, message);
  $("#toasts").append(node);
  setTimeout(() => node.remove(), 5000);
}

// Exécute une action déclenchée par un bouton et affiche l'erreur de l'API.
async function run(action) {
  try {
    await action();
  } catch (error) {
    toast(error.message, true);
  }
}

function showFormError(dialog, error) {
  const target = $(".form-error", dialog);
  target.textContent = error ? error.message : "";
  target.hidden = !error;
}

for (const cancel of document.querySelectorAll("[data-cancel]")) {
  cancel.addEventListener("click", () => cancel.closest("dialog").close());
}

// Branche un formulaire de boîte de dialogue sur un appel à l'API.
// L'erreur renvoyée par l'API reste affichée dans la boîte, qui ne se ferme
// qu'en cas de succès.
function bindSubmit(dialog, form, handler) {
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    showFormError(dialog, null);
    try {
      await handler(new FormData(form));
      dialog.close();
      await refresh();
    } catch (error) {
      showFormError(dialog, error);
    }
  });
}

// --- Onglets ---------------------------------------------------------------

// EXTRA-01 : Ajouter l'onglet Historique.
const tabs = ["games", "members", "loans"];
// FEAT-04 : Adhérent sélectionné pour consulter ses emprunts.
let selectedMember = null;
// FEAT-05 : Activer ou désactiver le filtre des retards.
let showOverdue = false;

function currentTab() {
  const name = location.hash.slice(1);
  return tabs.includes(name) ? name : "games";
}

// FEAT-05 : Actualiser le compteur des emprunts en retard.
async function updateOverdueCount() {
  const loans = await api.listOverdueLoans();
  const counter = $("#overdue-count");

  counter.textContent = `(${loans.length})`;
  counter.hidden = loans.length === 0;
}

async function refresh() {
  const tab = currentTab();
  // L'onglet Historique affiche toujours tous les emprunts par défaut.
  if (tab !== "loans") {
    selectedMember = null;
    showOverdue = false;
  }
  for (const name of tabs) {
    $(`#${name}`).hidden = name !== tab;
    $(`[data-tab="${name}"]`).toggleAttribute("aria-current", name === tab);
  }
  const loaders = {
    games: loadGames,
    members: loadMembers,
    loans: loadLoans,
  };
  await run(updateOverdueCount);
  await run(loaders[tab]);
}

window.addEventListener("hashchange", refresh);

// --- Jeux ------------------------------------------------------------------

async function loadGames() {
  const games = await api.listGames();
  $("#games-empty").hidden = games.length > 0;
  $("#games-list").replaceChildren(...games.map(gameCard));
}

function gameCard(game) {
  const players =
    game.minPlayers === game.maxPlayers ? `${game.minPlayers}` : `${game.minPlayers} à ${game.maxPlayers}`;

  const status = game.isAvailable
    ? el("span", { class: "badge ok" }, "Disponible")
    : el("span", { class: "badge busy" }, "Emprunté");

  const actions = el("div", { class: "actions" });
  // Afficher Emprunter ou Rendre selon la disponibilité.
  if (game.isAvailable) {
    actions.append(
      button("Emprunter", () => openBorrowDialog(game), "primary")
    );
  } else if (game.activeLoanID) {
    actions.append(
      button("Rendre", () => returnGame(game), "primary")
    );
  }

  // FEAT-01 : Actions de modification et de suppression.
  actions.append(
    button("Modifier", () => openEditGameDialog(game)),
    button("Supprimer", () => deleteGame(game))
  );

  return el(
    "li",
    { class: "card" },
    el("div", { class: "card-head" }, el("h3", {}, game.title), status),
    el("p", { class: "meta" }, `${players} joueur·ses · ${game.durationMinutes} min`),
    actions,
  );
}

// FEAT-01 : Supprimer un jeu après confirmation.
async function deleteGame(game) {
  const confirmed = confirm(
    `Voulez-vous vraiment supprimer « ${game.title} » ?`
  );

  if (!confirmed) return;

  await run(async () => {
    await api.deleteGame(game.id);

    toast(`« ${game.title} » a bien été supprimé.`);

    await refresh();
  });
}

const gameDialog = $("#game-dialog");
const gameForm = $("#game-form");

// FEAT-01 : Jeu en cours de modification (null = création).
let editingGame = null;

function openEditGameDialog(game) {
  editingGame = game;

  $("#game-dialog-title").textContent = "Modifier un jeu";

  gameForm.elements.namedItem("title").value = game.title;
  gameForm.elements.namedItem("minPlayers").value = game.minPlayers;
  gameForm.elements.namedItem("maxPlayers").value = game.maxPlayers;
  gameForm.elements.namedItem("durationMinutes").value = game.durationMinutes;

  showFormError(gameDialog, null);
  gameDialog.showModal();
}

$("#add-game").addEventListener("click", () => {
  editingGame = null;

  gameForm.reset();
  $("#game-dialog-title").textContent = "Ajouter un jeu";

  showFormError(gameDialog, null);
  gameDialog.showModal();
});

// FEAT-01 : Créer ou modifier un jeu selon le contexte.
bindSubmit(gameDialog, gameForm, (data) => {
  const game = {
    title: data.get("title").trim(),
    minPlayers: Number(data.get("minPlayers")),
    maxPlayers: Number(data.get("maxPlayers")),
    durationMinutes: Number(data.get("durationMinutes")),
  };

  if (editingGame) {
    return api.updateGame(editingGame.id, game);
  }

  return api.createGame(game);
});

// --- Emprunts --------------------------------------------------------------

// FEAT-03 : Enregistrer le retour du jeu et actualiser la liste.
async function returnGame(game) {
  await run(async () => {
    await api.returnLoan(game.activeLoanID);
    toast(`« ${game.title} » a bien été rendu.`);
    await refresh();
  });
}

const borrowDialog = $("#borrow-dialog");
const borrowForm = $("#borrow-form");
let borrowedGame = null;

async function openBorrowDialog(game) {
  await run(async () => {
    const members = await api.listMembers();
    if (members.length === 0) {
      toast("Ajoutez d'abord un·e adhérent·e pour pouvoir emprunter.", true);
      return;
    }
    borrowedGame = game;
    $("#borrow-dialog-title").textContent = `Emprunter « ${game.title} »`;
    $("select", borrowForm).replaceChildren(
      ...members.map((member) => el("option", { value: member.id }, `${member.name} (${member.email})`)),
    );
    showFormError(borrowDialog, null);
    borrowDialog.showModal();
  });
}

bindSubmit(borrowDialog, borrowForm, async (data) => {
  const loan = await api.borrow(borrowedGame.id, data.get("memberID"));
  toast(`« ${borrowedGame.title} » emprunté, à rendre avant le ${formatDate(loan.dueAt)}.`);
});

// --- Adhérent·es -----------------------------------------------------------

async function loadMembers() {
  const members = await api.listMembers();
  $("#members-empty").hidden = members.length > 0;
  $("#members-list").replaceChildren(...members.map(memberRow));
}

// FEAT-02 : Afficher un adhérent avec ses actions.
function memberRow(member) {
  return el(
    "li",
    { class: "row" },

    el(
      "div",
      { class: "row-main" },
      el("p", {}, el("strong", {}, member.name)),
      el("p", { class: "meta" }, member.email)
    ),

    el(
      "div",
      { class: "actions" },

      // FEAT-04 : Afficher les emprunts de cet adhérent.
      button("Voir les emprunts", () => {
        selectedMember = member;
        location.hash = "#loans";
      }),

      button("Modifier", () => {
        editingMember = member;
        $("#member-dialog-title").textContent = "Modifier un·e adhérent·e";
        memberForm.reset();
        memberForm.elements.name.value = member.name;
        memberForm.elements.email.value = member.email;
        showFormError(memberDialog, null);
        memberDialog.showModal();
      }),

      button("Supprimer", async () => {
        if (!confirm(`Supprimer ${member.name} ?`)) return;

        await run(async () => {
          await api.deleteMember(member.id);
          toast("Adhérent supprimé.");
          await refresh();
        });
      })
    )
  );
}

const memberDialog = $("#member-dialog");
const memberForm = $("#member-form");
// FEAT-02 : Adhérent en cours de modification (null = création).
let editingMember = null;

$("#add-member").addEventListener("click", () => {
  editingMember = null;
  $("#member-dialog-title").textContent = "Ajouter un·e adhérent·e";
  memberForm.reset();
  showFormError(memberDialog, null);
  memberDialog.showModal();
});

// FEAT-02 : Créer ou modifier un adhérent selon le contexte.
bindSubmit(memberDialog, memberForm, (data) => {
  const member = {
    name: data.get("name").trim(),
    email: data.get("email").trim(),
  };
  if (editingMember) {
    return api.updateMember(editingMember.id, member);
  }
  return api.createMember(member);
});

// --- Historique des emprunts -----------------------------------------------

// EXTRA-01 : Charger les emprunts et retrouver les noms des jeux et adhérent·es.
async function loadLoans() {
  const [loans, games, members] = await Promise.all([
    selectedMember
      ? api.listMemberLoans(selectedMember.id)
      : showOverdue
        ? api.listOverdueLoans()
        : api.listLoans(),
    api.listGames(),
    api.listMembers(),
  ]);
  $("#loans-title").textContent = selectedMember
    ? `Emprunts de ${selectedMember.name}`
    : showOverdue
      ? "Emprunts en retard"
      : "Historique des emprunts";

  $("#overdue-loans").hidden = !!selectedMember || showOverdue;
  $("#all-loans").hidden = !selectedMember && !showOverdue;
  // FEAT-05 : Adapter le message selon le filtre actif.
  $("#loans-empty").textContent = showOverdue
    ? "Aucun emprunt en retard."
    : selectedMember
      ? "Aucun emprunt pour cet adhérent."
      : "Aucun emprunt enregistré pour le moment.";
  $("#loans-empty").hidden = loans.length > 0;
  $("#loans-list").replaceChildren(
    ...loans.map((loan) => {
      const game = games.find((g) => g.id === loan.gameID);
      const member = members.find((m) => m.id === loan.memberID);

      // FEAT-05 : Calculer le retard d'un emprunt non rendu.
      const daysLate = loan.returnedAt
        ? 0
        : Math.max(0, Math.ceil(
            (Date.now() - new Date(loan.dueAt).getTime()) / 86_400_000
          ));
      const status = loan.returnedAt
        ? "Rendu"
        : daysLate > 0
          ? `En retard de ${daysLate} jour${daysLate > 1 ? "s" : ""}`
          : "En cours";

      return el(
        "li",
        { class: "row" },
        el(
          "div",
          { class: "row-main" },
          el("p", {}, el("strong", {}, game?.title ?? "Jeu inconnu")),
          el("p", { class: "meta" }, member?.name ?? "Adhérent·e inconnu·e"),
          el("p", { class: "meta" }, `Emprunté le ${formatDate(loan.borrowedAt)}`),
          el("p", { class: "meta" }, `Retour prévu le ${formatDate(loan.dueAt)}`),
          el(
            "p",
            { class: "meta" },
            loan.returnedAt
              ? `Rendu le ${formatDate(loan.returnedAt)}`
              : status,
          ),
        ),
      );
    }),
  );
}

// FEAT-04 : Revenir à l'historique global.
$("#all-loans").addEventListener("click", () => {
  selectedMember = null;
  showOverdue = false;
  refresh();
});

// FEAT-05 : Afficher uniquement les emprunts en retard.
$("#overdue-loans").addEventListener("click", () => {
  showOverdue = true;
  refresh();
});

refresh();



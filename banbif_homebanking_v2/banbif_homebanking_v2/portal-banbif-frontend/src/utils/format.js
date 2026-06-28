export function money(value) {
  return `S/ ${Number(value || 0).toFixed(2)}`;
}

export function maskAccount(number) {
  const text = String(number || "");
  if (!text) return "*******";
  return `*******${text.slice(-3)}`;
}

export function formatDate(value) {
  if (!value) return "Sin fecha";
  return new Date(value).toLocaleDateString("es-PE", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

export function formatDateTime(value) {
  if (!value) return "Sin fecha";
  return new Date(value).toLocaleString("es-PE", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function getAccountById(accounts, id) {
  return accounts.find((account) => Number(account.id) === Number(id));
}

export function accountLabel(account) {
  if (!account) return "";
  return `${maskAccount(account.account_number)} Ã‚Â· ${money(account.balance)}`;
}
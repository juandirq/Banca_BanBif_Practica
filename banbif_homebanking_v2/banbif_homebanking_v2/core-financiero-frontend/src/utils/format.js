export function formatMoney(value) {
  const number = Number(value || 0);

  return new Intl.NumberFormat("es-PE", {
    style: "currency",
    currency: "PEN",
    minimumFractionDigits: 2
  }).format(number);
}

export function formatDate(value) {
  if (!value) return "-";

  return new Date(value).toLocaleString("es-PE", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit"
  });
}

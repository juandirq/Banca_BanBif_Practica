export default function StatusBadge({ status }) {
  const value = status || "Sin estado";
  const normalized = value.toLowerCase().replaceAll(" ", "-");

  return <span className={`status-badge status-${normalized}`}>{value}</span>;
}

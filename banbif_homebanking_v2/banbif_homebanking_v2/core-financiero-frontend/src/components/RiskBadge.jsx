export default function RiskBadge({ risk }) {
  const value = risk || "SIN RIESGO";
  const className = `risk-badge risk-${value.toLowerCase()}`;

  return <span className={className}>{value}</span>;
}

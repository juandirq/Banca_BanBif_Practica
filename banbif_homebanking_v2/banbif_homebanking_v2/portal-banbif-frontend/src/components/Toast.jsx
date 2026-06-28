import { CheckCircle2, AlertCircle, Info } from "lucide-react";

export default function Toast({ toast }) {
  if (!toast?.text) return null;

  const Icon =
    toast.type === "error" ? AlertCircle :
    toast.type === "info" ? Info :
    CheckCircle2;

  return (
    <div className={`toast ${toast.type || "success"}`}>
      <Icon size={20} />
      <span>{toast.text}</span>
    </div>
  );
}
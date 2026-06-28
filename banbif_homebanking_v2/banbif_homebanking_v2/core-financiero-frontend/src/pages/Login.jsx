import { useState } from "react";
import {
  Building2,
  Eye,
  EyeOff,
  LockKeyhole,
  ShieldCheck,
  UserRoundCheck
} from "lucide-react";

import { loginAnalyst } from "../services/coreApi";

export default function Login({ onLogin }) {
  const [usuario, setUsuario] = useState("");
  const [clave, setClave] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function ingresar(e) {
    e.preventDefault();

    if (!usuario.trim() || !clave.trim()) {
      setError("Ingresa tu usuario y contraseña.");
      return;
    }

    try {
      setLoading(true);
      setError("");

      const data = await loginAnalyst(usuario, clave);

      if (!data.access_token) {
        throw new Error("No se recibio token JWT del backend Core.");
      }

      sessionStorage.setItem("coreAnalyst", JSON.stringify(data.analyst));
      sessionStorage.setItem("coreToken", data.access_token);
      onLogin(data.analyst);
    } catch (err) {
      setError("Usuario o contraseña incorrectos.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="login-shell">
      <section className="login-card">
        <div className="login-icon">
          <Building2 size={34} />
        </div>

        <p className="eyebrow">Acceso seguro interno</p>
        <h1>Banca Interna BanBif</h1>

        <p className="login-subtitle">
          Plataforma exclusiva para analistas autorizados. Desde este módulo se
          revisan solicitudes de crédito, riesgo, scoring y decisiones internas.
        </p>

        <div className="login-security-note">
          <ShieldCheck size={18} />
          Acceso restringido a personal autorizado
        </div>

        <form onSubmit={ingresar} className="login-form">
          <label>
            Usuario interno
            <div className="login-input">
              <UserRoundCheck size={18} />
              <input
                value={usuario}
                onChange={(e) => setUsuario(e.target.value)}
                placeholder="Ingresa tu usuario"
                autoComplete="username"
              />
            </div>
          </label>

          <label>
            Contraseña
            <div className="login-input">
              <LockKeyhole size={18} />

              <input
                type={showPassword ? "text" : "password"}
                value={clave}
                onChange={(e) => setClave(e.target.value)}
                placeholder="Ingresa tu contraseña"
                autoComplete="current-password"
              />

              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </label>

          {error && <div className="login-error">{error}</div>}

          <button type="submit" className="login-btn" disabled={loading}>
            {loading ? "Validando..." : "Ingresar"}
          </button>
        </form>
      </section>
    </main>
  );
}

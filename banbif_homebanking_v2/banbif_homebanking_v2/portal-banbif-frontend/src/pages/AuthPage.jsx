import { useState } from "react";
import { Eye, EyeOff, Landmark, ShieldCheck } from "lucide-react";
import Toast from "../components/Toast";

export default function AuthPage({
  authMode,
  setAuthMode,
  loginForm,
  setLoginForm,
  registerForm,
  setRegisterForm,
  handleLogin,
  handleRegister,
  loading,
  toast,
}) {
  const [showLoginPassword, setShowLoginPassword] = useState(false);
  const [showRegisterPassword, setShowRegisterPassword] = useState(false);
  const [showLandingBanbif, setShowLandingBanbif] = useState(true);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  if (showLandingBanbif) {
    return (
      <main className="banbif-public-home">
        <header className="banbif-public-navbar">
          <div className="banbif-public-logo">BanBif</div>

          <nav className="banbif-public-menu">
            <span>Personas</span>
            <span>Empresas</span>
            <span>Nuestros productos</span>
            <span>Contenido Digital</span>
            <span>Ayuda y atención</span>
          </nav>

          <div className="banbif-public-actions">
            <button
              type="button"
              className="banbif-btn-outline"
              onClick={() => {
                setAuthMode("login");
                setShowLandingBanbif(false);
              }}
            >
              Banca por Internet
            </button>

            <button
              type="button"
              className="banbif-btn-primary"
              onClick={() => {
                setAuthMode("register");
                setShowLandingBanbif(false);
              }}
            >
              Abrir cuenta
            </button>
          </div>
        </header>

        <section className="banbif-public-hero">
          <div className="banbif-hero-copy">
            <span className="banbif-eyebrow">Banca Digital BanBif</span>
            <h1>Tu banco simple, seguro y siempre contigo</h1>
            <p>
              Consulta tus cuentas, realiza transferencias, pagos y solicita productos
              financieros desde una experiencia digital moderna.
            </p>

            <div className="banbif-hero-buttons">
              <button
                type="button"
                className="banbif-btn-hero"
                onClick={() => {
                  setAuthMode("login");
                  setShowLandingBanbif(false);
                }}
              >
                Entrar a banca
              </button>

              <button
                type="button"
                className="banbif-btn-hero-secondary"
                onClick={() => {
                  setAuthMode("register");
                  setShowLandingBanbif(false);
                }}
              >
                Abrir cuenta
              </button>
            </div>
          </div>

          <div className="banbif-hero-visual">
            <div className="banbif-glow"></div>
            <div className="banbif-phone-card">
              <span>Cuenta Ahorro Digital</span>
              <strong>S/ 2,810.10</strong>
              <small>Disponible para operaciones</small>
            </div>
            <div className="banbif-card-floating card-one">Transferencias y PLIN</div>
            <div className="banbif-card-floating card-two">Pagos de servicios</div>
            <div className="banbif-card-floating card-three">Créditos BanBif</div>
          </div>
        </section>

        <section className="banbif-public-options">
          <h2>¿Qué quieres hacer hoy?</h2>

          <div className="banbif-option-grid">
            <article>
              <span>01</span>
              <h3>Entrar a banca digital</h3>
              <p>Accede con tu DNI y contraseña para consultar tus productos.</p>
            </article>

            <article>
              <span>02</span>
              <h3>Abrir una cuenta</h3>
              <p>Registra tus datos y crea tu usuario bancario digital.</p>
            </article>

            <article>
              <span>03</span>
              <h3>Solicitar crédito</h3>
              <p>Simula y registra solicitudes personales o vehiculares.</p>
            </article>
          </div>
        </section>

        <button
          type="button"
          className="banbif-floating-login"
          onClick={() => {
            setAuthMode("login");
            setShowLandingBanbif(false);
          }}
        >
          Cuenta Ahorro Digital
        </button>
      </main>
    );
  }
  return (
    <main className="auth-page">
      <section className="auth-hero">
        <div className="brand">
          <div className="brand-icon">
            <Landmark size={30} />
          </div>
          <div>
            <h1>BanBif</h1>
            <p>Banca digital segura para tus operaciones diarias</p>
          </div>
        </div>

        <div className="hero-content">
          <span className="badge">
            <ShieldCheck size={16} />
            Acceso seguro
          </span>

          <h2>Gestiona tus cuentas, pagos, transferencias y creditos desde un portal bancario.</h2>

          <p>
            Consulta tus saldos, opera con tus cuentas, realiza pagos y da seguimiento
            a tus solicitudes desde una plataforma ordenada por modulos.
          </p>

          <div className="hero-stats">
            <div>
              <strong>24/7</strong>
              <span>Acceso digital</span>
            </div>
            <div>
              <strong>+Cuentas</strong>
              <span>Varias cuentas</span>
            </div>
            <div>
              <strong>Seguro</strong>
              <span>Sesion protegida</span>
            </div>
          </div>
        </div>
      </section>

      <section className="auth-panel">
        <div className="auth-card">
          <div className="auth-title">
            <Landmark />
            <div>
              <h2>{authMode === "login" ? "Iniciar sesion" : "Crear cuenta"}</h2>
              <p>
                {authMode === "login"
                  ? "Ingresa con tu documento o correo registrado."
                  : "Completa tus datos para crear tu usuario bancario."}
              </p>
            </div>
          </div>

          {authMode === "login" ? (
            <form onSubmit={handleLogin} className="form">
              <label>Correo o documento</label>
              <input
                value={loginForm.identifier}
                onChange={(e) => setLoginForm({ ...loginForm, identifier: e.target.value })}
                placeholder="Ejemplo: 99999994"
                required
              />

              <label>Contrasena</label>
              <div className="password-field">
                <input
                  type={showLoginPassword ? "text" : "password"}
                  value={loginForm.password}
                  onChange={(e) => setLoginForm({ ...loginForm, password: e.target.value })}
                  placeholder="Ingresa tu contrasena"
                  required
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowLoginPassword(!showLoginPassword)}
                  aria-label={showLoginPassword ? "Ocultar contrasena" : "Mostrar contrasena"}
                >
                  {showLoginPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>

              <button className="primary" disabled={loading}>
                {loading ? "Ingresando..." : "Iniciar sesion"}
              </button>

              <p className="auth-switch">
                No tienes una cuenta?{" "}
                <button type="button" onClick={() => setAuthMode("register")}>
                  Registrate
                </button>
              </p>
            </form>
          ) : (
            <form onSubmit={handleRegister} className="form">
              <label>Nombre completo</label>
              <input
                value={registerForm.name}
                onChange={(e) => setRegisterForm({ ...registerForm, name: e.target.value })}
                placeholder="Ejemplo: Juan Perez"
                required
              />

              <label>Correo</label>
              <input
                type="email"
                value={registerForm.email}
                onChange={(e) => setRegisterForm({ ...registerForm, email: e.target.value })}
                placeholder="Ejemplo: juan@email.com"
                required
              />

              <label>Documento</label>
              <input
                value={registerForm.document}
                onChange={(e) => setRegisterForm({ ...registerForm, document: e.target.value })}
                placeholder="Ejemplo: 99999999"
                required
              />

              <label>Telefono</label>
              <input
                value={registerForm.phone}
                onChange={(e) => setRegisterForm({ ...registerForm, phone: e.target.value })}
                placeholder="Ejemplo: 987654321"
                required
              />

              <label>Direccion</label>
              <input
                value={registerForm.address}
                onChange={(e) => setRegisterForm({ ...registerForm, address: e.target.value })}
                placeholder="Ejemplo: El Tambo, Huancayo, Peru"
                required
              />

              <label>Contrasena</label>
              <div className="password-field">
                <input
                  type={showRegisterPassword ? "text" : "password"}
                  value={registerForm.password}
                  onChange={(e) => setRegisterForm({ ...registerForm, password: e.target.value })}
                  placeholder="Crea una contrasena"
                  required
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowRegisterPassword(!showRegisterPassword)}
                  aria-label={showRegisterPassword ? "Ocultar contrasena" : "Mostrar contrasena"}
                >
                  {showRegisterPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>

              <label>Confirmar contrasena</label>
              <div className="password-field">
                <input
                  type={showConfirmPassword ? "text" : "password"}
                  value={registerForm.confirm_password}
                  onChange={(e) => setRegisterForm({ ...registerForm, confirm_password: e.target.value })}
                  placeholder="Repite tu contrasena"
                  required
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  aria-label={showConfirmPassword ? "Ocultar contrasena" : "Mostrar contrasena"}
                >
                  {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>

              <button className="primary" disabled={loading}>
                {loading ? "Creando cuenta..." : "Registrarme"}
              </button>

              <p className="auth-switch">
                Ya tienes una cuenta?{" "}
                <button type="button" onClick={() => setAuthMode("login")}>
                  Inicia sesion
                </button>
              </p>
            </form>
          )}
        </div>
      </section>

      <Toast toast={toast} />
    </main>
  );
}

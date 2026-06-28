import { useEffect, useMemo, useState } from "react";
import api from "./services/api";
import { getAccountById } from "./utils/format";
import { getBankAlerts, isInsufficientBalance } from "./utils/banking";
import Layout from "./components/Layout";
import AuthPage from "./pages/AuthPage";
import SummaryPage from "./pages/SummaryPage";
import SavingsPage from "./pages/SavingsPage";
import PaymentsPage from "./pages/PaymentsPage";
import TransfersPage from "./pages/TransfersPage";
import CreditsPage from "./pages/CreditsPage";
import ProfilePage from "./pages/ProfilePage";

const TOKEN_DEMO = "123456";

const initialLogin = {
  identifier: "",
  password: "",
};

const initialRegister = {
  name: "",
  email: "",
  document: "",
  phone: "",
  address: "",
  password: "",
  confirm_password: "",
};

export default function App() {
  const [authMode, setAuthMode] = useState("login");
  const [activePage, setActivePage] = useState("resumen");

  const [user, setUser] = useState(null);
  const [dashboard, setDashboard] = useState(null);

  const [loginForm, setLoginForm] = useState(initialLogin);
  const [registerForm, setRegisterForm] = useState(initialRegister);

  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState({ text: "", type: "success" });

  const [newAccountForm, setNewAccountForm] = useState({
    account_type: "Cuenta Ahorro Digital",
    currency: "PEN",
    accept_terms: false,
  });

  const [depositForm, setDepositForm] = useState({
    account_id: "",
    amount: "",
    description: "",
  });

  const [paymentForm, setPaymentForm] = useState({
    account_id: "",
    service: "",
    contract_number: "",
    amount: "",
    confirm_payment: false,
    token_digital: "",
  });

  const [transferForm, setTransferForm] = useState({
    transfer_type: "",
    from_account_id: "",
    to_account_number: "",
    to_contact_phone: "",
    amount: "",
    description: "",
    confirm_transfer: false,
    token_digital: "",
  });

  const [creditForm, setCreditForm] = useState({
    product: "Prestamo Efectivo BanBif",
    amount: "",
    term_months: "12",
    monthly_income: "",
    purpose: "Libre disponibilidad",
    location: "Lima",
    income_type: "fijo",
    income_category: "5ta",
    employment_type: "dependiente",
    employment_months: "12",
    marital_status: "soltero",
    spouse_documents: "no",
    bad_credit_history: "pendiente_validacion",
  });

  const accounts = dashboard?.accounts || [];
  const movements = dashboard?.last_movements || [];
  const credits = dashboard?.credits || [];
  const payments = dashboard?.payments || [];

  const metrics = useMemo(() => {
    const paymentTotal = payments.reduce((sum, p) => sum + Number(p.monto || 0), 0);
    const creditTotal = credits.reduce((sum, c) => sum + Number(c.amount || 0), 0);
    const transfers = movements.filter((m) => {
      const operation = String(m.operation_type || "").toLowerCase();
      const description = String(m.description || "").toLowerCase();

      return (
        operation.includes("transferencia") ||
        operation.includes("plin") ||
        description.includes("plin")
      );
    }).length;

    const pendingCredits = credits.filter((c) =>
      String(c.status || "").toLowerCase().includes("evalu")
    ).length;

    return {
      paymentsCount: payments.length,
      creditsCount: credits.length,
      paymentTotal,
      creditTotal,
      transfers,
      pendingCredits,
    };
  }, [payments, credits, movements]);

  const alerts = useMemo(() => getBankAlerts({ accounts, credits }), [accounts, credits]);

  useEffect(() => {
    const savedUser = localStorage.getItem("banbif_user");
    const savedToken = localStorage.getItem("banbif_token");

    if (savedToken && savedUser) {
      setUser(JSON.parse(savedUser));
      loadDashboard();
    }
  }, []);

  function showMessage(text, type = "success") {
    setToast({ text, type });
    window.setTimeout(() => {
      setToast({ text: "", type: "success" });
    }, 3800);
  }

  async function loadDashboard() {
    try {
      const response = await api.get("/api/dashboard");
      setDashboard(response.data);
    } catch {
      localStorage.removeItem("banbif_token");
      localStorage.removeItem("banbif_user");
      setUser(null);
      setDashboard(null);
    }
  }

  async function handleLogin(e) {
    e.preventDefault();
    setLoading(true);

    try {
      const response = await api.post("/api/login", loginForm);

      localStorage.setItem("banbif_token", response.data.access_token);
      localStorage.setItem("banbif_user", JSON.stringify(response.data.user));

      setUser(response.data.user);
      setDashboard(response.data.dashboard_preview);
      setActivePage("resumen");

      loadDashboard();
      showMessage("Sesion iniciada correctamente.", "success");
    } catch (error) {
      showMessage(error.response?.data?.detail || "No se pudo iniciar sesion.", "error");
    } finally {
      setLoading(false);
    }
  }

  async function handleRegister(e) {
    e.preventDefault();

    const payload = {
      name: registerForm.name.trim(),
      email: registerForm.email.trim().toLowerCase(),
      document: registerForm.document.trim(),
      phone: registerForm.phone.trim(),
      address: registerForm.address.trim(),
      password: registerForm.password,
    };

    if (registerForm.password !== registerForm.confirm_password) {
      showMessage("Las contrasenas no coinciden.", "error");
      return;
    }

    if (registerForm.password.length < 6) {
      showMessage("La contrasena debe tener al menos 6 caracteres.", "error");
      return;
    }

    setLoading(true);

    try {
      const response = await api.post("/api/register", payload);

      localStorage.setItem("banbif_token", response.data.access_token);
      localStorage.setItem("banbif_user", JSON.stringify(response.data.user));

      setUser(response.data.user);
      setDashboard(response.data.dashboard_preview);
      setActivePage("resumen");
      setRegisterForm(initialRegister);

      loadDashboard();
      showMessage("Cuenta creada y sesion iniciada correctamente.", "success");
    } catch (error) {
      const detail = error.response?.data?.detail;
      const message = typeof detail === "string" ? detail : "No se pudo crear la cuenta.";

      const canTryAutoLogin =
        !error.response ||
        message.toLowerCase().includes("ya existe un usuario") ||
        String(error.message || "").toLowerCase().includes("network");

      if (canTryAutoLogin) {
        try {
          const loginResponse = await api.post("/api/login", {
            identifier: payload.email || payload.document,
            password: payload.password,
          });

          localStorage.setItem("banbif_token", loginResponse.data.access_token);
          localStorage.setItem("banbif_user", JSON.stringify(loginResponse.data.user));

          setUser(loginResponse.data.user);
          setDashboard(loginResponse.data.dashboard_preview);
          setActivePage("resumen");
          setRegisterForm(initialRegister);

          loadDashboard();
          showMessage("Sesion iniciada correctamente.", "success");
          return;
        } catch {
          showMessage(message, "error");
          return;
        }
      }

      showMessage(message, "error");
    } finally {
      setLoading(false);
    }
  }

  function logout() {
    localStorage.removeItem("banbif_token");
    localStorage.removeItem("banbif_user");
    setUser(null);
    setDashboard(null);
    setLoginForm(initialLogin);
    setRegisterForm(initialRegister);
    setAuthMode("login");
    showMessage("Sesion cerrada correctamente.", "success");
  }

  function goTo(page) {
    setActivePage(page);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  async function createAccount(e) {
    e.preventDefault();

    if (!newAccountForm.accept_terms) {
      showMessage("Debes aceptar las condiciones para abrir una cuenta.", "error");
      return;
    }

    setLoading(true);

    try {
      await api.post("/api/cuentas/crear", {
        account_type: newAccountForm.account_type,
        currency: newAccountForm.currency,
      });

      setNewAccountForm({
        account_type: "Cuenta Ahorro Digital",
        currency: "PEN",
        accept_terms: false,
      });

      await loadDashboard();
      showMessage("Cuenta Ahorro Digital creada correctamente.", "success");
    } catch (error) {
      showMessage(error.response?.data?.detail || "No se pudo crear la cuenta.", "error");
    } finally {
      setLoading(false);
    }
  }

  async function makeDeposit(e) {
    e.preventDefault();

    if (Number(depositForm.amount) <= 0) {
      showMessage("El monto del deposito debe ser mayor a cero.", "error");
      return;
    }

    setLoading(true);

    try {
      await api.post("/api/ahorros/deposito", {
        account_id: Number(depositForm.account_id),
        amount: Number(depositForm.amount),
        description: depositForm.description || "Deposito en cuenta",
      });

      setDepositForm({ ...depositForm, amount: "", description: "" });
      await loadDashboard();
      showMessage("Deposito realizado correctamente.", "success");
    } catch (error) {
      showMessage(error.response?.data?.detail || "No se pudo realizar el deposito.", "error");
    } finally {
      setLoading(false);
    }
  }

  async function makePayment(e) {
    e.preventDefault();

    const account = getAccountById(accounts, paymentForm.account_id);

    if (!account) {
      showMessage("Selecciona una cuenta de pago.", "error");
      return;
    }

    if (!paymentForm.service) {
      showMessage("Selecciona el tipo de pago.", "error");
      return;
    }

    if (Number(paymentForm.amount) <= 0) {
      showMessage("El monto del pago debe ser mayor a cero.", "error");
      return;
    }

    if (isInsufficientBalance(account.balance, paymentForm.amount)) {
      showMessage("Saldo insuficiente para procesar el pago.", "error");
      return;
    }

    if (!paymentForm.confirm_payment) {
      showMessage("Confirma los datos del pago antes de continuar.", "error");
      return;
    }

    if (paymentForm.token_digital !== TOKEN_DEMO) {
      showMessage("Token Digital incorrecto.", "error");
      return;
    }

    setLoading(true);

    try {
      await api.post("/api/pagos", {
        account_id: Number(paymentForm.account_id),
        service: paymentForm.service,
        contract_number: paymentForm.contract_number,
        amount: Number(paymentForm.amount),
        token_digital: paymentForm.token_digital,
      });

      setPaymentForm({
        account_id: "",
        service: "",
        contract_number: "",
        amount: "",
        confirm_payment: false,
        token_digital: "",
      });

      await loadDashboard();
      showMessage("Pago confirmado con Token Digital.", "success");
    } catch (error) {
      showMessage(error.response?.data?.detail || "No se pudo realizar el pago.", "error");
    } finally {
      setLoading(false);
    }
  }

  async function makeTransfer(e) {
    e.preventDefault();

    const origin = getAccountById(accounts, transferForm.from_account_id);

    if (!origin) {
      showMessage("Selecciona una cuenta origen.", "error");
      return;
    }

    if (!transferForm.transfer_type) {
      showMessage("Selecciona el tipo de transferencia.", "error");
      return;
    }

    if (transferForm.transfer_type === "cuenta" && !transferForm.to_account_number.trim()) {
      showMessage("Ingresa el numero completo de cuenta destino.", "error");
      return;
    }

    if (transferForm.transfer_type === "plin" && !transferForm.to_contact_phone.trim()) {
      showMessage("Ingresa el celular afiliado a PLIN interoperable.", "error");
      return;
    }

    if (Number(transferForm.amount) <= 0) {
      showMessage("El monto de transferencia debe ser mayor a cero.", "error");
      return;
    }

    if (isInsufficientBalance(origin.balance, transferForm.amount)) {
      showMessage("Saldo insuficiente para realizar la transferencia.", "error");
      return;
    }

    if (!transferForm.confirm_transfer) {
      showMessage("Confirma los datos de la transferencia antes de continuar.", "error");
      return;
    }

    if (transferForm.token_digital !== TOKEN_DEMO) {
      showMessage("Token Digital incorrecto.", "error");
      return;
    }

    if (transferForm.transfer_type === "cuenta" && origin.account_number === transferForm.to_account_number) {
      showMessage("No puedes transferir a la misma cuenta de origen.", "error");
      return;
    }

    setLoading(true);

    try {
      if (transferForm.transfer_type === "plin") {
        await api.post("/api/transferencias/plin", {
          from_account_id: Number(transferForm.from_account_id),
          phone: transferForm.to_contact_phone,
          amount: Number(transferForm.amount),
          token_digital: transferForm.token_digital,
          description: transferForm.description || "Transferencia PLIN interoperable",
        });
      } else {
        await api.post("/api/transferencias", {
          from_account_id: Number(transferForm.from_account_id),
          to_account_number: transferForm.to_account_number,
          amount: Number(transferForm.amount),
          description: transferForm.description || "Transferencia entre cuentas",
          token_digital: transferForm.token_digital,
        });
      }

      setTransferForm({
        transfer_type: "",
        from_account_id: "",
        to_account_number: "",
        to_contact_phone: "",
        amount: "",
        description: "",
        confirm_transfer: false,
        token_digital: "",
      });

      await loadDashboard();
      showMessage("Transferencia confirmada con Token Digital.", "success");
    } catch (error) {
      showMessage(error.response?.data?.detail || "No se pudo realizar la transferencia.", "error");
    } finally {
      setLoading(false);
    }
  }

  async function requestCredit(e) {
    e.preventDefault();

    if (!(creditForm.product || creditForm.producto || "Prestamo Efectivo BanBif")) {
      showMessage("Selecciona el producto de credito.", "error");
      return;
    }

    if (Number(creditForm.amount) <= 0 || Number(creditForm.monthly_income) <= 0) {
      showMessage("El monto y el ingreso mensual deben ser mayores a cero.", "error");
      return;
    }

    setLoading(true);

    try {
      await api.post("/api/creditos/solicitar", {
        product: creditForm.product || "Prestamo Efectivo BanBif",
        amount: Number(creditForm.amount),
        term_months: Number(creditForm.term_months),
        monthly_income: Number(creditForm.monthly_income),
        purpose: creditForm.purpose || "Libre disponibilidad",
        location: creditForm.location || "Lima",
        income_type: creditForm.income_type || "fijo",
        income_category: creditForm.income_category || "5ta",
        employment_type: creditForm.income_category === "5ta" ? "dependiente" : "independiente",
        employment_months: Number(creditForm.employment_months || 12),
        marital_status: creditForm.marital_status || "soltero",
        spouse_documents: creditForm.spouse_documents || "no",
        bad_credit_history: "pendiente_validacion",
      });

      setCreditForm({
        product: "Prestamo Efectivo BanBif",
        amount: "",
        term_months: "12",
        monthly_income: "",
        purpose: "Libre disponibilidad",
      });
      await loadDashboard();
      showMessage("Solicitud de credito registrada correctamente.", "success");
    } catch (error) {
      showMessage(error.response?.data?.detail || "No se pudo registrar el credito.", "error");
    } finally {
      setLoading(false);
    }
  }

  if (!user) {
    return (
      <AuthPage
        authMode={authMode}
        setAuthMode={setAuthMode}
        loginForm={loginForm}
        setLoginForm={setLoginForm}
        registerForm={registerForm}
        setRegisterForm={setRegisterForm}
        handleLogin={handleLogin}
        handleRegister={handleRegister}
        loading={loading}
        toast={toast}
      />
    );
  }

  return (
    <Layout
      user={user}
      activePage={activePage}
      onNavigate={goTo}
      onLogout={logout}
      onRefresh={loadDashboard}
      alerts={alerts}
      toast={toast}
    >
      {activePage === "resumen" && (
        <SummaryPage dashboard={dashboard} metrics={metrics} alerts={alerts} onNavigate={goTo} />
      )}

      {activePage === "ahorros" && (
        <SavingsPage
          accounts={accounts}
          movements={movements}
          depositForm={depositForm}
          setDepositForm={setDepositForm}
          newAccountForm={newAccountForm}
          setNewAccountForm={setNewAccountForm}
          makeDeposit={makeDeposit}
          createAccount={createAccount}
          loading={loading}
          onFeedback={showMessage}
        />
      )}

      {activePage === "pagos" && (
        <PaymentsPage
          accounts={accounts}
          payments={payments}
          paymentForm={paymentForm}
          setPaymentForm={setPaymentForm}
          makePayment={makePayment}
          loading={loading}
        />
      )}

      {activePage === "transferencias" && (
        <TransfersPage
          accounts={accounts}
          movements={movements}
          transferForm={transferForm}
          setTransferForm={setTransferForm}
          makeTransfer={makeTransfer}
          loading={loading}
          onFeedback={showMessage}
        />
      )}

      {activePage === "creditos" && (
        <CreditsPage
          credits={credits}
          creditForm={creditForm}
          setCreditForm={setCreditForm}
          requestCredit={requestCredit}
          loading={loading}
        />
      )}

      {activePage === "perfil" && <ProfilePage user={user} />}
    </Layout>
  );
}


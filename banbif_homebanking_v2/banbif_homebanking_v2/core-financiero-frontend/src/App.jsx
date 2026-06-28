import { useState } from "react";
import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login";
import "./App.css";

function getStoredAnalyst() {
  try {
    const data = sessionStorage.getItem("coreAnalyst");
    return data ? JSON.parse(data) : null;
  } catch {
    return null;
  }
}

export default function App() {
  const [analyst, setAnalyst] = useState(getStoredAnalyst);

  function handleLogin(user) {
    setAnalyst(user);
  }

  function handleLogout() {
    sessionStorage.removeItem("coreAnalyst");
    sessionStorage.removeItem("coreToken");
    setAnalyst(null);
  }

  if (!analyst) {
    return <Login onLogin={handleLogin} />;
  }

  return <Dashboard analyst={analyst} onLogout={handleLogout} />;
}

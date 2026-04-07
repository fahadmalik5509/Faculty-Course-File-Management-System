import { loginWithRole } from "./auth-helpers.js";

const form = document.getElementById("loginForm");
const messageEl = document.getElementById("message");

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;

  messageEl.textContent = "Signing in...";
  messageEl.style.color = "#1a73e8";

  try {
    await loginWithRole(email, password, "admin");
    window.location.href = "../dashboard/admin-dashboard.html";
  } catch (error) {
    messageEl.textContent = error.message || "Login failed. Check email/password.";
    messageEl.style.color = "#d93025";
  }
});

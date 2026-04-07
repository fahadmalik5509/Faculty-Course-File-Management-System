import { apiRequest } from "./api-client.js";

async function loginWithRole(email, password, expectedRole) {
  const data = await apiRequest("/login.php", {
    method: "POST",
    body: JSON.stringify({ email, password, expectedRole })
  });

  return data.user;
}

async function getCurrentUser() {
  const data = await apiRequest("/me.php", { method: "GET" });
  return data.user || null;
}

async function protectPage(expectedRole, onAllowed) {
  try {
    const user = await getCurrentUser();

    if (!user || user.role !== expectedRole) {
      window.location.href = "../home.html";
      return;
    }

    onAllowed(user);
  } catch (error) {
    console.error(error);
    window.location.href = "../home.html";
  }
}

async function logoutToHome() {
  await apiRequest("/logout.php", { method: "POST" });
  window.location.href = "../home.html";
}

export { loginWithRole, protectPage, logoutToHome, getCurrentUser };

function getApiBase() {
  const marker = "/frontend/";
  const path = window.location.pathname;
  const markerIndex = path.indexOf(marker);
  const rootPath = markerIndex >= 0 ? path.slice(0, markerIndex) : "";
  return `${window.location.origin}${rootPath}/backend/api`;
}

async function apiRequest(path, options = {}) {
  const response = await fetch(`${getApiBase()}${path}`, {
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {})
    },
    ...options
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok || data.ok === false) {
    const message = data.message || `Request failed (${response.status})`;
    throw new Error(message);
  }

  return data;
}

export { apiRequest };

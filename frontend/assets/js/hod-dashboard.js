import { apiRequest } from "./api-client.js";
import { logoutToHome, protectPage } from "./auth-helpers.js";

const reviewTableBody = document.getElementById("reviewTableBody");
const pendingCountEl = document.getElementById("pending-count");
const completionRateEl = document.getElementById("rate");
const logoutButton = document.getElementById("logoutButton");

let cachedRows = [];

function buildRow(item) {
  const tr = document.createElement("tr");
  tr.dataset.id = item.id;

  const fileCell = item.downloadURL
    ? `<a href="${item.downloadURL}" class="file-link" target="_blank" rel="noopener noreferrer">${item.fileName}</a>`
    : `<span>${item.fileName}</span>`;

  tr.innerHTML = `
    <td>${item.facultyName}</td>
    <td>${item.courseName}</td>
    <td>${item.fileType}</td>
    <td>${fileCell}</td>
    <td>
      <button type="button" class="btn-approve" data-action="approve" data-id="${item.id}">Approve</button>
      <button type="button" class="btn-reject" data-action="reject" data-id="${item.id}">Reject</button>
    </td>
  `;

  return tr;
}

function refreshMetrics() {
  const total = cachedRows.length;
  const pending = cachedRows.filter((item) => item.status === "pending").length;
  const completed = total - pending;
  const rate = total === 0 ? 0 : Math.round((completed / total) * 100);

  pendingCountEl.textContent = String(pending);
  completionRateEl.textContent = `${rate}%`;
}

function subscribeReviewQueue() {
  loadReviewQueue();
}

async function loadReviewQueue() {
  const data = await apiRequest("/uploads.php?scope=all", { method: "GET" });
  cachedRows = data.items.map((item) => ({
    id: Number(item.id),
    facultyName: item.faculty_name,
    courseName: item.course_name,
    fileType: item.file_type,
    fileName: item.file_name,
    status: item.status
  }));

  reviewTableBody.innerHTML = "";
  cachedRows.forEach((item) => {
    if (item.status === "pending") {
      reviewTableBody.appendChild(buildRow(item));
    }
  });

  refreshMetrics();
}

reviewTableBody.addEventListener("click", async (event) => {
  const button = event.target.closest("button");
  if (!button) {
    return;
  }

  const itemId = button.dataset.id;
  const action = button.dataset.action;
  if (!itemId || !action) {
    return;
  }

  try {
    if (action === "approve") {
      await apiRequest("/review-action.php", {
        method: "POST",
        body: JSON.stringify({ id: Number(itemId), action: "approve" })
      });
      alert("Document approved successfully.");
      await loadReviewQueue();
      return;
    }

    if (action === "reject") {
      const feedback = window.prompt("Enter rejection feedback for the faculty member:");
      if (!feedback) {
        return;
      }

      await apiRequest("/review-action.php", {
        method: "POST",
        body: JSON.stringify({ id: Number(itemId), action: "reject", feedback })
      });
      alert("Feedback saved and status set to rejected.");
      await loadReviewQueue();
    }
  } catch (error) {
    alert(error.message || "Action failed.");
  }
});

document.querySelectorAll(".btn-report").forEach((button) => {
  button.addEventListener("click", () => {
    const reportType = button.dataset.report;
    alert(`Report generation placeholder: ${reportType}`);
  });
});

logoutButton.addEventListener("click", async (event) => {
  event.preventDefault();
  await logoutToHome();
});

protectPage("hod", () => {
  subscribeReviewQueue();
});

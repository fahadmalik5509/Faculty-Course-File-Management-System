import { apiRequest } from "./api-client.js";
import { logoutToHome, protectPage } from "./auth-helpers.js";

const form = document.getElementById("courseAllocationForm");
const facultySelect = document.getElementById("facultySelect");
const courseSelect = document.getElementById("courseSelect");
const allocationList = document.getElementById("allocationList");
const submitButton = form.querySelector("button[type='submit']");
const facultyCountEl = document.getElementById("faculty-count");
const courseCountEl = document.getElementById("course-count");
const fileCountEl = document.getElementById("file-count");
const logoutButton = document.getElementById("logoutButton");

let editAllocationId = null;

function setEditMode(docId, facultyName, courseName) {
  editAllocationId = docId;

  for (let i = 0; i < facultySelect.options.length; i += 1) {
    if (facultySelect.options[i].text === facultyName) {
      facultySelect.selectedIndex = i;
      break;
    }
  }

  for (let i = 0; i < courseSelect.options.length; i += 1) {
    if (courseSelect.options[i].text === courseName) {
      courseSelect.selectedIndex = i;
      break;
    }
  }

  submitButton.textContent = "Update Allocation";
  submitButton.style.backgroundColor = "#f2994a";
}

function resetFormMode() {
  editAllocationId = null;
  form.reset();
  submitButton.textContent = "Allocate Course";
  submitButton.style.backgroundColor = "";
}

function renderAllocationRow(item) {
  const row = document.createElement("tr");
  row.dataset.id = item.id;

  row.innerHTML = `
    <td>${item.facultyName}</td>
    <td>${item.courseName}</td>
    <td><span style="color: green; font-weight: 700;">Active</span></td>
    <td>
      <button type="button" class="action-edit" data-id="${item.id}">Edit</button>
      <button type="button" class="action-delete" data-id="${item.id}">Delete</button>
    </td>
  `;

  return row;
}

async function loadAllocations() {
  const data = await apiRequest("/allocations.php", { method: "GET" });
  allocationList.innerHTML = "";
  const uniqueCourses = new Set();

  data.items.forEach((item) => {
    uniqueCourses.add(item.course_name);
    allocationList.appendChild(
      renderAllocationRow({
        id: item.id,
        facultyName: item.faculty_name,
        courseName: item.course_name
      })
    );
  });

  courseCountEl.textContent = String(uniqueCourses.size);
}

async function loadStats() {
  const data = await apiRequest("/admin-stats.php", { method: "GET" });
  facultyCountEl.textContent = String(data.stats.facultyCount);
  courseCountEl.textContent = String(data.stats.courseCount);
  fileCountEl.textContent = String(data.stats.fileCount);
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const facultyName = facultySelect.options[facultySelect.selectedIndex].text;
  const courseName = courseSelect.options[courseSelect.selectedIndex].text;

  if (!facultySelect.value || !courseSelect.value) {
    return;
  }

  try {
    if (editAllocationId) {
      await apiRequest("/allocations.php", {
        method: "PUT",
        body: JSON.stringify({ id: Number(editAllocationId), facultyName, courseName })
      });
    } else {
      await apiRequest("/allocations.php", {
        method: "POST",
        body: JSON.stringify({ facultyName, courseName })
      });
    }

    resetFormMode();
    await loadAllocations();
    await loadStats();
  } catch (error) {
    alert(error.message || "Unable to save allocation.");
  }
});

allocationList.addEventListener("click", async (event) => {
  const target = event.target;
  const button = target.closest("button");

  if (!button) {
    return;
  }

  const itemId = button.dataset.id;
  if (!itemId) {
    return;
  }

  if (button.classList.contains("action-edit")) {
    const row = button.closest("tr");
    setEditMode(itemId, row.cells[0].textContent, row.cells[1].textContent);
    return;
  }

  if (button.classList.contains("action-delete")) {
    const shouldDelete = window.confirm("Delete this allocation?");
    if (!shouldDelete) {
      return;
    }

    try {
      await apiRequest("/allocations.php", {
        method: "DELETE",
        body: JSON.stringify({ id: Number(itemId) })
      });

      if (editAllocationId === itemId) {
        resetFormMode();
      }
      await loadAllocations();
      await loadStats();
    } catch (error) {
      alert(error.message || "Unable to delete allocation.");
    }
  }
});

logoutButton.addEventListener("click", async (event) => {
  event.preventDefault();
  await logoutToHome();
});

protectPage("admin", () => {
  loadAllocations();
  loadStats();
});

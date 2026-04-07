import { apiRequest } from "./api-client.js";
import { logoutToHome, protectPage } from "./auth-helpers.js";

const form = document.getElementById("uploadForm");
const facultySelect = document.getElementById("facultySelect");
const courseSelect = document.getElementById("courseSelect");
const fileTypeSelect = document.getElementById("fileType");
const fileInput = document.getElementById("fileInput");
const statusMessage = document.getElementById("statusMessage");
const tableBody = document.getElementById("fileListBody");
const submitButton = form.querySelector(".btn-submit");
const welcomeName = document.getElementById("welcomeName");
const logoutButton = document.getElementById("logoutButton");

const maxSize = 20 * 1024 * 1024;
let currentUid = "";
let editRecordId = null;

function setStatus(message, color) {
  statusMessage.textContent = message;
  statusMessage.style.color = color;
}

function resetFormMode() {
  editRecordId = null;
  submitButton.textContent = "Save File Record";
  submitButton.style.backgroundColor = "";
  form.reset();
}

function renderUploadRow(item) {
  const tr = document.createElement("tr");
  tr.dataset.id = item.id;

  tr.innerHTML = `
    <td style="padding: 12px;">${item.courseName}</td>
    <td style="padding: 12px;">${item.fileType}</td>
    <td style="padding: 12px; font-style: italic;">${item.fileName}</td>
    <td style="padding: 12px;">
      <button type="button" class="action-edit" data-id="${item.id}">Edit</button>
      <button type="button" class="action-delete" data-id="${item.id}">Delete</button>
    </td>
  `;

  return tr;
}

function subscribeUploads() {
  loadUploads();
}

async function loadUploads() {
  const data = await apiRequest("/uploads.php?scope=mine", { method: "GET" });
  tableBody.innerHTML = "";
  data.items.forEach((item) => {
    tableBody.appendChild(
      renderUploadRow({
        id: item.id,
        courseName: item.course_name,
        fileType: item.file_type,
        fileName: item.file_name
      })
    );
  });
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const facultyName = facultySelect.options[facultySelect.selectedIndex].text;
  const courseName = courseSelect.options[courseSelect.selectedIndex].text;
  const fileType = fileTypeSelect.value;
  const file = fileInput.files[0] || null;

  if (!facultySelect.value || !courseSelect.value || !fileType) {
    return;
  }

  if (!editRecordId && !file) {
    setStatus("Please choose a file to upload.", "#d93025");
    return;
  }

  if (file && file.size > maxSize) {
    setStatus("Error: File exceeds 20MB limit.", "#d93025");
    return;
  }

  setStatus("Processing...", "#1a73e8");

  try {
    if (editRecordId) {
      const updatePayload = {
        id: Number(editRecordId),
        facultyName,
        courseName,
        fileType
      };

      if (file) {
        updatePayload.fileName = file.name;
      }

      await apiRequest("/uploads.php", {
        method: "PUT",
        body: JSON.stringify(updatePayload)
      });
      setStatus("Record updated successfully.", "#ef6c00");
    } else {
      await apiRequest("/uploads.php", {
        method: "POST",
        body: JSON.stringify({
          facultyName,
          courseName,
          fileType,
          fileName: file.name
        })
      });

      setStatus("File record saved (free mode: no cloud file upload).", "#188038");
    }

    resetFormMode();
    await loadUploads();
  } catch (error) {
    setStatus(error.message || "Upload failed.", "#d93025");
  }
});

tableBody.addEventListener("click", async (event) => {
  const button = event.target.closest("button");
  if (!button) {
    return;
  }

  const itemId = button.dataset.id;
  if (!itemId) {
    return;
  }

  const row = button.closest("tr");

  if (button.classList.contains("action-edit")) {
    editRecordId = itemId;

    const courseText = row.cells[0].textContent.trim();
    const fileType = row.cells[1].textContent.trim();

    for (let i = 0; i < courseSelect.options.length; i += 1) {
      if (courseSelect.options[i].text === courseText) {
        courseSelect.selectedIndex = i;
        break;
      }
    }

    fileTypeSelect.value = fileType;

    const data = await apiRequest("/uploads.php?scope=mine", { method: "GET" });
    const selected = data.items.find((item) => Number(item.id) === Number(itemId));
    if (selected) {
      for (let i = 0; i < facultySelect.options.length; i += 1) {
        if (facultySelect.options[i].text === selected.faculty_name) {
          facultySelect.selectedIndex = i;
          break;
        }
      }
    }

    submitButton.textContent = "Update Record";
    submitButton.style.backgroundColor = "#f2994a";
    setStatus("Editing record. Re-select file only if you want to replace it.", "#ef6c00");
    return;
  }

  if (button.classList.contains("action-delete")) {
    const shouldDelete = window.confirm("Remove this uploaded record?");
    if (!shouldDelete) {
      return;
    }

    try {
      await apiRequest("/uploads.php", {
        method: "DELETE",
        body: JSON.stringify({ id: Number(itemId) })
      });

      if (editRecordId === itemId) {
        resetFormMode();
      }

      setStatus("File removed.", "#d93025");
      await loadUploads();
    } catch (error) {
      setStatus(error.message || "Delete failed.", "#d93025");
    }
  }
});

logoutButton.addEventListener("click", async (event) => {
  event.preventDefault();
  await logoutToHome();
});

protectPage("teacher", (user) => {
  currentUid = user.id;
  welcomeName.textContent = user.email;
  subscribeUploads();
});

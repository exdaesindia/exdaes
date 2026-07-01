const navToggle = document.querySelector(".nav-toggle");
const navLinks = document.querySelector(".nav-links");

if (navToggle && navLinks) {
  navToggle.addEventListener("click", () => {
    navLinks.classList.toggle("open");
  });

  navLinks.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => navLinks.classList.remove("open"));
  });
}

document.querySelectorAll("[data-formspree-form]").forEach((form) => {
  const examSelect = form.querySelector('select[name="Entrance Exam Appeared"]');
  const otherExamField = form.querySelector("[data-other-exam-field]");
  const otherExamInput = otherExamField?.querySelector("input");
  const submitButton = form.querySelector('button[type="submit"]');
  const successMessage = form.querySelector(".success-message");
  const defaultSuccessMessage = successMessage?.textContent ?? "";

  const syncOtherExamField = () => {
    if (!examSelect || !otherExamField || !otherExamInput) {
      return;
    }

    const showOtherField = examSelect.value === "Other";
    otherExamField.hidden = !showOtherField;
    otherExamInput.required = showOtherField;

    if (!showOtherField) {
      otherExamInput.value = "";
    }
  };

  syncOtherExamField();
  examSelect?.addEventListener("change", syncOtherExamField);

  form.addEventListener("submit", async (event) => {
    event.preventDefault();

    if (submitButton) {
      submitButton.disabled = true;
      submitButton.dataset.originalText = submitButton.textContent ?? "";
      submitButton.textContent = "Submitting...";
    }

    try {
      const response = await fetch(form.action, {
        method: form.method || "POST",
        body: new FormData(form),
        headers: {
          Accept: "application/json",
        },
      });

      if (!response.ok) {
        throw new Error("Form submission failed");
      }

      form.classList.add("is-success");
      form.reset();
      syncOtherExamField();

      if (successMessage) {
        successMessage.textContent = defaultSuccessMessage || "Thank you. Your details have been received.";
      }
    } catch (error) {
      form.classList.add("is-success");

      if (successMessage) {
        successMessage.textContent = "We could not submit the form right now. Please try again or contact us on WhatsApp.";
      }
    } finally {
      if (submitButton) {
        submitButton.disabled = false;
        submitButton.textContent = submitButton.dataset.originalText || "Submit";
      }
    }
  });
});

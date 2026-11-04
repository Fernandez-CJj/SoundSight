(() => {
  "use strict";

  const config = window.SOUNDSIGHT_CONFIG;
  const setText = (selector, value) => {
    document.querySelectorAll(selector).forEach((element) => {
      element.textContent = value;
    });
  };
  setText("[data-version]", config.version);
  setText("[data-android]", config.minimumAndroid);
  setText("[data-file-size]", `${Math.round(config.fileSizeBytes / 1000000)} MB`);
  setText("[data-checksum]", config.sha256);

  const dialog = document.getElementById("download-dialog");
  let returnFocusTarget;
  document.querySelectorAll("[data-open-download]").forEach((button) => {
    button.setAttribute("aria-haspopup", "dialog");
    button.setAttribute("aria-controls", dialog.id);
    button.addEventListener("click", () => {
      returnFocusTarget = button;
      dialog.showModal();
      document.body.classList.add("dialog-open");
    });
  });
  document.querySelectorAll("[data-close-download]").forEach((button) => {
    button.addEventListener("click", () => {
      if (button.getAttribute("href") === "#installation") {
        returnFocusTarget = document.getElementById("installation");
      }
      dialog.close();
    });
  });
  dialog.addEventListener("close", () => {
    document.body.classList.remove("dialog-open");
    returnFocusTarget?.focus({ preventScroll: true });
  });
  // Closing only when a full pointer gesture is outside avoids accidental closes
  // when someone drags selected text from inside the panel to the backdrop.
  let pointerStartedOutside = false;
  const isOutsideDialog = (event) => {
    const rect = dialog.getBoundingClientRect();
    return event.clientX < rect.left || event.clientX > rect.right ||
      event.clientY < rect.top || event.clientY > rect.bottom;
  };
  dialog.addEventListener("pointerdown", (event) => {
    pointerStartedOutside = event.target === dialog && isOutsideDialog(event);
  });
  dialog.addEventListener("click", (event) => {
    if (pointerStartedOutside && event.target === dialog && isOutsideDialog(event)) dialog.close();
    pointerStartedOutside = false;
  });

  // Empty URLs deliberately render an honest UI preview, never a broken download.
  // This can be connected later without changing any download button markup.
  let downloadUrl;
  try {
    const parsed = new URL(config.downloadUrl);
    if (parsed.protocol === "https:") downloadUrl = parsed.href;
  } catch { /* No release URL has been configured yet. */ }
  if (downloadUrl) {
    const link = document.getElementById("apk-download");
    link.href = downloadUrl;
    link.hidden = false;
    document.getElementById("download-unavailable").hidden = true;
    document.getElementById("download-status").textContent =
      "Save the app file on your Android phone, then follow the install steps. You install it without Google Play.";
  }

  // Indicate the section being read without interfering with native anchor links.
  const navLinks = [...document.querySelectorAll(".main-nav a")];
  const sections = navLinks.map((link) => document.querySelector(link.getAttribute("href")));
  if ("IntersectionObserver" in window) {
    const visibleSections = new Set();
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) visibleSections.add(entry.target.id);
        else visibleSections.delete(entry.target.id);
      });
      const active = sections.find((section) => visibleSections.has(section.id));
      navLinks.forEach((link) => {
        if (active && link.hash === `#${active.id}`) link.setAttribute("aria-current", "location");
        else link.removeAttribute("aria-current");
      });
    }, { rootMargin: "-20% 0px -45% 0px", threshold: 0 });
    sections.forEach((section) => observer.observe(section));
  }

  const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");

  // Native scrolling works without JavaScript; controls add one-card navigation.
  const testimonials = document.getElementById("testimonials-list");
  const previousReview = document.querySelector("[data-testimonial-previous]");
  const nextReview = document.querySelector("[data-testimonial-next]");
  if (testimonials && previousReview && nextReview) {
    document.querySelector("[data-testimonial-controls]").hidden = false;
    const updateReviewControls = () => {
      const end = Math.max(0, testimonials.scrollWidth - testimonials.clientWidth);
      previousReview.disabled = testimonials.scrollLeft <= 1;
      nextReview.disabled = testimonials.scrollLeft >= end - 1;
    };
    const scrollReviews = (direction) => {
      const card = testimonials.firstElementChild;
      if (!card) return;
      const gap = parseFloat(window.getComputedStyle(testimonials).columnGap) || 0;
      testimonials.scrollBy({
        left: direction * (card.getBoundingClientRect().width + gap),
        behavior: motionPreference.matches ? "auto" : "smooth",
      });
    };
    previousReview.addEventListener("click", () => scrollReviews(-1));
    nextReview.addEventListener("click", () => scrollReviews(1));
    testimonials.addEventListener("scroll", updateReviewControls, { passive: true });
    testimonials.addEventListener("keydown", (event) => {
      if (event.target !== testimonials || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
      if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
        event.preventDefault();
        scrollReviews(event.key === "ArrowRight" ? 1 : -1);
      } else if (event.key === "Home" || event.key === "End") {
        event.preventDefault();
        testimonials.scrollTo({
          left: event.key === "Home" ? 0 : testimonials.scrollWidth - testimonials.clientWidth,
          behavior: motionPreference.matches ? "auto" : "smooth",
        });
      }
    });
    window.addEventListener("resize", updateReviewControls);
    updateReviewControls();
  }

  // Add animation only when content enters view. Nothing is hidden while waiting,
  // so the page stays readable without JavaScript or observer support.
  const readyToReveal = new WeakSet();
  let revealObserver;
  const revealSelector = [
    ".hero-phone-preview", ".section-heading", ".lesson-card",
    ".practice-card", ".testimonials-list", ".steps-grid > li",
    ".download-card", ".faq-section > div:first-child",
    ".faq-list > details", ".site-footer",
  ].join(", ");
  const finishReveal = (element) => {
    element.classList.remove("scroll-reveal");
    element.style.removeProperty("--reveal-delay");
  };
  const observeReveals = () => {
    revealObserver?.disconnect();
    if (motionPreference.matches || !("IntersectionObserver" in window)) return;

    revealObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) {
          finishReveal(entry.target);
          readyToReveal.add(entry.target);
        }
      });
      const entering = entries.filter((entry) => entry.isIntersecting &&
        entry.intersectionRatio >= 0.12 && readyToReveal.has(entry.target));
      entering.sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top ||
        a.boundingClientRect.left - b.boundingClientRect.left);
      entering.forEach((entry, index) => {
        const element = entry.target;
        readyToReveal.delete(element);
        // Keyboard navigation should never leave a focused control faded out.
        if (motionPreference.matches || element.contains(document.activeElement)) return;
        element.style.setProperty("--reveal-delay", `${Math.min(index, 3) * 75}ms`);
        element.classList.add("scroll-reveal");
      });
    }, { threshold: [0, 0.12] });

    document.querySelectorAll(revealSelector).forEach((element) => {
      const rect = element.getBoundingClientRect();
      // Leave the initial viewport untouched, including restored scroll positions.
      if (rect.height > 0 && rect.top < window.innerHeight && rect.bottom > 0) {
        readyToReveal.delete(element);
      } else {
        readyToReveal.add(element);
      }
      // Keep watching so each full exit allows another animation on return.
      revealObserver.observe(element);
    });
  };
  document.addEventListener("animationend", (event) => {
    if (event.animationName === "content-reveal") finishReveal(event.target);
  });
  document.addEventListener("focusin", (event) => {
    const element = event.target.closest(".scroll-reveal");
    if (element) finishReveal(element);
  });
  motionPreference.addEventListener("change", () => {
    document.querySelectorAll(".scroll-reveal").forEach(finishReveal);
    observeReveals();
  });
  observeReveals();
})();

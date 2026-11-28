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

  // Only display contact details supplied by the project owner.
  try {
    const supportUrl = new URL(config.supportUrl);
    if (supportUrl.protocol === "https:") {
      document.querySelectorAll("[data-support-link]").forEach((link) => { link.href = supportUrl.href; });
    }
  } catch { /* Keep the project support link in the HTML. */ }
  const supportEmail = typeof config.supportEmail === "string" ? config.supportEmail.trim() : "";
  if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(supportEmail)) {
    const emailLink = document.querySelector("[data-support-email]");
    emailLink.href = `mailto:${encodeURIComponent(supportEmail)}`;
    emailLink.textContent = supportEmail;
    document.querySelector("[data-support-email-card]").hidden = false;
  }

  // This event describes an APK request, not a finished transfer or installation.
  // An optional server collector can aggregate requests by UTC day. The app must
  // report installations independently; this page cannot observe an Android install.
  const trackDownloadRequest = () => {
    const occurredAt = new Date().toISOString();
    const payload = {
      event: "download_requested",
      source: "landing_page",
      platform: "android",
      appVersion: config.version,
      occurredAt,
      day: occurredAt.slice(0, 10),
      timeZone: "UTC",
    };
    window.dispatchEvent(new CustomEvent("soundsight:download-requested", { detail: payload }));
    if (!config.downloadTrackingEndpoint) return;
    let endpoint;
    try {
      endpoint = new URL(config.downloadTrackingEndpoint, document.baseURI);
      if (endpoint.protocol !== "https:") return;
    } catch { return; }
    const body = JSON.stringify(payload);
    try {
      if (navigator.sendBeacon?.(endpoint.href, new Blob([body], { type: "application/json" }))) return;
    } catch { /* Fall back without delaying the download link. */ }
    fetch(endpoint.href, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
      keepalive: true,
      credentials: "omit",
      referrerPolicy: "no-referrer",
    }).catch(() => { /* A collector failure must not block the download. */ });
  };

  const dialog = document.getElementById("download-dialog");
  let returnFocusTarget;
  document.querySelectorAll("[data-open-download]").forEach((button) => {
    button.setAttribute("aria-haspopup", "dialog");
    button.setAttribute("aria-controls", dialog.id);
    button.addEventListener("click", () => {
      returnFocusTarget = button;
      dialog.showModal();
      dialog.scrollTop = 0;
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
    link.addEventListener("click", trackDownloadRequest);
    link.addEventListener("auxclick", (event) => {
      if (event.button === 1) trackDownloadRequest();
    });
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

  // Keep each review in one paragraph, with its disclosure button below it.
  // Without JavaScript, the complete review stays visible.
  document.querySelectorAll(".testimonial-toggle").forEach((button) => {
    const continuation = document.getElementById(button.getAttribute("aria-controls"));
    const ellipsis = button.closest(".testimonial-quote").querySelector(".testimonial-ellipsis");
    const setExpanded = (expanded) => {
      continuation.hidden = !expanded;
      ellipsis.hidden = expanded;
      button.setAttribute("aria-expanded", String(expanded));
    };
    setExpanded(false);
    button.hidden = false;
    button.addEventListener("click", () => {
      setExpanded(button.getAttribute("aria-expanded") !== "true");
    });
  });

  // Page whole cards instead of exposing a clipped next review. Ten reviews
  // are initially available; Show more reveals the remaining static entries.
  const testimonials = document.getElementById("testimonials-list");
  const previousReview = document.querySelector("[data-testimonial-previous]");
  const nextReview = document.querySelector("[data-testimonial-next]");
  const moreReviews = document.querySelector("[data-show-more-reviews]");
  const pagination = document.getElementById("testimonial-pagination");
  if (testimonials && previousReview && nextReview) {
    const cards = [...testimonials.querySelectorAll(".testimonial-card")];
    const initialLimit = Number.parseInt(testimonials.dataset.reviewLimit, 10) || 10;
    let reviewLimit = Math.min(initialLimit, cards.length);
    let currentPage = 0;
    let columns = 1;
    let resizeFrame;
    document.querySelector("[data-testimonial-controls]").hidden = false;
    document.querySelector("[data-testimonial-footer]").hidden = false;

    const getColumns = () => Math.max(1,
      Number.parseInt(window.getComputedStyle(testimonials).getPropertyValue("--review-columns"), 10) || 1);
    const pageCount = () => Math.max(1, Math.ceil(reviewLimit / columns));
    const renderReviews = () => {
      currentPage = Math.max(0, Math.min(currentPage, pageCount() - 1));
      const start = currentPage * columns;
      const end = Math.min(start + columns, reviewLimit);
      const focusedCard = cards.find((card) => card.contains(document.activeElement));
      cards.forEach((card, index) => { card.hidden = index < start || index >= end; });
      previousReview.disabled = currentPage === 0;
      nextReview.disabled = currentPage >= pageCount() - 1;
      if (moreReviews) moreReviews.hidden = reviewLimit >= cards.length;
      if (pagination) {
        const text = reviewLimit ? `Reviews ${start + 1} to ${end} of ${reviewLimit}` : "No reviews yet";
        if (pagination.textContent !== text) pagination.textContent = text;
      }
      if (focusedCard?.hidden) testimonials.focus({ preventScroll: true });
    };

    // Measure collapsed copies, including off-page reviews, without touching
    // an expanded original or stretching neighboring cards.
    const updateCollapsedReviewHeight = () => {
      if (!cards.length || testimonials.getBoundingClientRect().width === 0) return;
      const measurement = testimonials.cloneNode(true);
      measurement.removeAttribute("id");
      measurement.removeAttribute("aria-describedby");
      measurement.classList.remove("scroll-reveal");
      measurement.setAttribute("aria-hidden", "true");
      measurement.inert = true;
      measurement.style.removeProperty("--testimonial-collapsed-height");
      Object.assign(measurement.style, {
        position: "fixed",
        top: "0",
        left: "0",
        width: `${testimonials.getBoundingClientRect().width}px`,
        visibility: "hidden",
        pointerEvents: "none",
      });
      measurement.querySelectorAll("[id]").forEach((element) => element.removeAttribute("id"));
      measurement.querySelectorAll(".testimonial-card").forEach((card) => { card.hidden = false; });
      measurement.querySelectorAll(".testimonial-continuation").forEach((element) => { element.hidden = true; });
      measurement.querySelectorAll(".testimonial-ellipsis").forEach((element) => { element.hidden = false; });
      measurement.querySelectorAll(".testimonial-toggle").forEach((button) => {
        button.setAttribute("aria-expanded", "false");
        button.removeAttribute("aria-controls");
      });
      testimonials.after(measurement);
      try {
        const height = Math.ceil(Math.max(...[...measurement.children].map((card) => card.getBoundingClientRect().height)));
        testimonials.style.setProperty("--testimonial-collapsed-height", `${height}px`);
      } finally {
        measurement.remove();
      }
    };
    const changePage = (direction) => {
      currentPage += direction;
      renderReviews();
    };
    previousReview.addEventListener("click", () => changePage(-1));
    nextReview.addEventListener("click", () => changePage(1));
    moreReviews?.addEventListener("click", () => {
      const firstNewReview = reviewLimit;
      reviewLimit = cards.length;
      currentPage = Math.floor(firstNewReview / columns);
      renderReviews();
      testimonials.focus({ preventScroll: true });
    });
    testimonials.addEventListener("keydown", (event) => {
      if (event.target !== testimonials || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
      if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
        event.preventDefault();
        changePage(event.key === "ArrowRight" ? 1 : -1);
      } else if (event.key === "Home" || event.key === "End") {
        event.preventDefault();
        currentPage = event.key === "Home" ? 0 : pageCount() - 1;
        renderReviews();
      }
    });
    let swipeStart;
    testimonials.addEventListener("pointerdown", (event) => {
      swipeStart = null;
      if (event.pointerType === "touch" && !event.target.closest("button, a")) {
        swipeStart = { x: event.clientX, y: event.clientY };
      }
    }, { passive: true });
    testimonials.addEventListener("pointerup", (event) => {
      if (!swipeStart || event.pointerType !== "touch") return;
      const dx = event.clientX - swipeStart.x;
      const dy = event.clientY - swipeStart.y;
      swipeStart = null;
      if (Math.abs(dx) >= 48 && Math.abs(dx) > Math.abs(dy) * 1.4) changePage(dx < 0 ? 1 : -1);
    }, { passive: true });
    testimonials.addEventListener("pointercancel", () => { swipeStart = null; });

    const updateReviewLayout = () => {
      const firstVisible = currentPage * columns;
      columns = getColumns();
      currentPage = Math.floor(firstVisible / columns);
      renderReviews();
      updateCollapsedReviewHeight();
    };
    const scheduleReviewLayout = () => {
      cancelAnimationFrame(resizeFrame);
      resizeFrame = requestAnimationFrame(updateReviewLayout);
    };
    window.addEventListener("resize", scheduleReviewLayout);
    if ("ResizeObserver" in window) {
      let previousWidth = -1;
      new ResizeObserver(([entry]) => {
        if (entry.contentRect.width !== previousWidth) {
          previousWidth = entry.contentRect.width;
          scheduleReviewLayout();
        }
      }).observe(testimonials);
    }
    updateReviewLayout();
    document.fonts?.ready.then(updateReviewLayout);
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

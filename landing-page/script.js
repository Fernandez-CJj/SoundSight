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

  // Keep the tab orientation and keyboard controls consistent with the layout.
  const tablist = document.querySelector('[role="tablist"]');
  const tabs = [...tablist.querySelectorAll('[role="tab"]')];
  const horizontalTabs = window.matchMedia("(max-width: 800px)");
  const updateOrientation = () => {
    tablist.setAttribute("aria-orientation", horizontalTabs.matches ? "horizontal" : "vertical");
  };
  updateOrientation();
  horizontalTabs.addEventListener("change", updateOrientation);

  const selectTab = (selectedTab, moveFocus = false) => {
    tabs.forEach((tab) => {
      const isSelected = tab === selectedTab;
      tab.setAttribute("aria-selected", String(isSelected));
      tab.tabIndex = isSelected ? 0 : -1;
      document.getElementById(tab.getAttribute("aria-controls")).hidden = !isSelected;
    });
    if (moveFocus) selectedTab.focus();
  };
  tabs.forEach((tab, index) => {
    tab.addEventListener("click", () => selectTab(tab));
    tab.addEventListener("keydown", (event) => {
      const previousKey = horizontalTabs.matches ? "ArrowLeft" : "ArrowUp";
      const nextKey = horizontalTabs.matches ? "ArrowRight" : "ArrowDown";
      let nextIndex;
      if (event.key === previousKey) nextIndex = (index + tabs.length - 1) % tabs.length;
      else if (event.key === nextKey) nextIndex = (index + 1) % tabs.length;
      else if (event.key === "Home") nextIndex = 0;
      else if (event.key === "End") nextIndex = tabs.length - 1;
      else return;
      event.preventDefault();
      selectTab(tabs[nextIndex], true);
    });
  });

  // Open the native disclosure before following an in-page link to the guide.
  document.querySelectorAll("[data-open-ar-guide]").forEach((link) => {
    link.addEventListener("click", () => {
      document.getElementById("ar-setup").open = true;
    });
  });

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

  // Screenshot links still open the original file when JavaScript is unavailable.
  const screenshotDialog = document.getElementById("screenshot-dialog");
  const screenshotImage = document.getElementById("screenshot-image");
  const sourceImages = new Map([...document.querySelectorAll("[data-open-screenshot] img")]
    .map((image) => [image.getAttribute("src"), image]));
  let screenshotTrigger;
  document.querySelectorAll("[data-open-screenshot]").forEach((link) => {
    if (typeof screenshotDialog.showModal !== "function") return;
    link.setAttribute("aria-haspopup", "dialog");
    link.setAttribute("aria-controls", screenshotDialog.id);
    link.addEventListener("click", (event) => {
      if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      event.preventDefault();
      screenshotTrigger = link;
      const path = link.getAttribute("href");
      const original = sourceImages.get(path);
      document.getElementById("screenshot-title").textContent = link.dataset.previewTitle;
      screenshotImage.src = path;
      screenshotImage.alt = original?.alt || link.dataset.previewTitle;
      screenshotImage.width = Number(original?.getAttribute("width")) || 1080;
      screenshotImage.height = Number(original?.getAttribute("height")) || 2400;
      screenshotDialog.showModal();
      document.body.classList.add("dialog-open");
    });
  });
  document.querySelector("[data-close-screenshot]").addEventListener("click", () => screenshotDialog.close());
  screenshotDialog.addEventListener("close", () => {
    document.body.classList.remove("dialog-open");
    screenshotTrigger?.focus({ preventScroll: true });
  });
  let screenshotPointerOutside = false;
  const isOutsideScreenshot = (event) => {
    const rect = screenshotDialog.getBoundingClientRect();
    return event.clientX < rect.left || event.clientX > rect.right ||
      event.clientY < rect.top || event.clientY > rect.bottom;
  };
  screenshotDialog.addEventListener("pointerdown", (event) => {
    screenshotPointerOutside = event.target === screenshotDialog && isOutsideScreenshot(event);
  });
  screenshotDialog.addEventListener("click", (event) => {
    if (screenshotPointerOutside && event.target === screenshotDialog && isOutsideScreenshot(event)) {
      screenshotDialog.close();
    }
    screenshotPointerOutside = false;
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
      "Download the APK on your Android device, then follow the installation guide. This app is installed outside Google Play.";
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

  // Add animation only when content enters view. Nothing is hidden while waiting,
  // so the page stays readable without JavaScript or observer support.
  const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");
  const revealed = new WeakSet();
  let revealObserver;
  const revealSelector = [
    ".hero-screen-card", ".section-heading", ".practice-layout", ".capability", ".steps-grid > li",
    ".download-card", ".permissions-note", ".faq-section > div:first-child",
    ".faq-list > details", ".ar-setup-guide > summary", ".ar-guide-intro",
    ".ar-guide-steps > li", ".ar-guide-finish", ".site-footer",
  ].join(", ");
  const finishReveal = (element) => {
    element.classList.remove("scroll-reveal");
    element.style.removeProperty("--reveal-delay");
  };
  const observeReveals = () => {
    revealObserver?.disconnect();
    if (motionPreference.matches || !("IntersectionObserver" in window)) return;

    revealObserver = new IntersectionObserver((entries) => {
      const entering = entries.filter((entry) => entry.isIntersecting);
      entering.sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top ||
        a.boundingClientRect.left - b.boundingClientRect.left);
      entering.forEach((entry, index) => {
        const element = entry.target;
        revealed.add(element);
        revealObserver.unobserve(element);
        // Keyboard navigation should never leave a focused control faded out.
        if (motionPreference.matches || element.contains(document.activeElement)) return;
        element.style.setProperty("--reveal-delay", `${Math.min(index, 3) * 75}ms`);
        element.classList.add("scroll-reveal");
      });
    }, { rootMargin: "0px 0px -32px 0px", threshold: 0.12 });

    document.querySelectorAll(revealSelector).forEach((element) => {
      if (revealed.has(element)) return;
      const rect = element.getBoundingClientRect();
      // Leave the initial viewport untouched, including restored scroll positions.
      if (rect.height > 0 && rect.top < window.innerHeight && rect.bottom > 0) {
        revealed.add(element);
      } else {
        revealObserver.observe(element);
      }
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

document.addEventListener("turbo:load", () => {
  // Find all star-rating containers
  const containers = document.querySelectorAll(".star-rating");
  if (!containers.length) return;

  containers.forEach((container) => {
    const stars = container.querySelectorAll("label.star");

    stars.forEach((label) => {
      // Get the radio button associated with this label
      const radioId = label.getAttribute("for");
      const radio = document.getElementById(radioId);
      if (!radio) return;

      const ratingValue = parseInt(radio.value);

      // ===== Click Handler =====
      label.addEventListener("click", (e) => {
        e.preventDefault();
        
        // Check the radio button
        radio.checked = true;
        
        // Update all stars in this container
        updateStars(container, ratingValue);
      });

      // ===== Hover Handler =====
      label.addEventListener("mouseenter", () => {
        updateStars(container, ratingValue, true); // preview = true
      });

      // ===== Unhover Handler =====
      label.addEventListener("mouseleave", () => {
        // Show actual selected rating, not preview
        const selectedRadio = Array.from(container.querySelectorAll("input[type='radio']")).find(
          (r) => r.checked
        );
        if (selectedRadio) {
          updateStars(container, parseInt(selectedRadio.value), false);
        } else {
          // Reset all to empty
          container.querySelectorAll("label.star i").forEach((icon) => {
            icon.classList.remove("bi-star-fill");
            icon.classList.add("bi-star");
            icon.classList.remove("text-warning");
            icon.classList.add("text-muted");
          });
        }
      });
    });

    // Set initial state if a rating is already selected
    const selectedRadio = container.querySelector("input[type='radio']:checked");
    if (selectedRadio) {
      updateStars(container, parseInt(selectedRadio.value), false);
    }
  });
});

/**
 * Update star display
 * @param {Element} container - The .star-rating container
 * @param {Number} rating - The rating value (1-5)
 * @param {Boolean} preview - Whether this is a preview (hover) or actual selection
 */
function updateStars(container, rating, preview = false) {
  const icons = container.querySelectorAll("label.star i");

  icons.forEach((icon, index) => {
    const starNumber = index + 1;

    if (starNumber <= rating) {
      // Filled star
      icon.classList.remove("bi-star");
      icon.classList.add("bi-star-fill");
      icon.classList.remove("text-muted");
      icon.classList.add("text-warning");
    } else {
      // Empty star
      icon.classList.remove("bi-star-fill");
      icon.classList.add("bi-star");
      icon.classList.remove("text-warning");
      icon.classList.add("text-muted");
    }
  });
}

document.addEventListener("turbo:load", () => {
  const container = document.querySelector("#star-rating");
  if (!container) return;

  const stars = container.querySelectorAll(".star");

  stars.forEach((star) => {
    star.addEventListener("click", () => {
      const selected = parseInt(star.dataset.value);

      // Update star colors
      stars.forEach((s) => {
        const value = parseInt(s.dataset.value);
        s.classList.toggle("text-warning", value <= selected);
        s.classList.toggle("text-muted", value > selected);
      });

      // Check the corresponding radio input
      const radio = document.getElementById(`rating-${selected}`);
      if (radio) radio.checked = true;
    });
  });
});

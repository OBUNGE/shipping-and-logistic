document.addEventListener("DOMContentLoaded", () => {
  const mpesaOption   = document.querySelector("#provider_mpesa");
  const paypalOption  = document.querySelector("#provider_paypal");
  const cardOption    = document.querySelector("#provider_paystack");
  const podOption     = document.querySelector("#provider_pod");
  const mpesaPhone    = document.querySelector("#mpesa_phone_number");
  const mpesaField    = document.querySelector("#mpesa_phone_field");
  const countySelect  = document.querySelector("#order_county");
  const cityInput     = document.querySelector("#order_city");
  const podNote       = document.querySelector("#pod-note");

  function toggleMpesaRequirement() {
    if (mpesaOption.checked) {
      mpesaPhone.required = true;
      mpesaField.style.display = "block";
    } else {
      mpesaPhone.required = false;
      mpesaField.style.display = "none";
    }
  }

  function togglePOD() {
    const county = countySelect?.value?.toLowerCase() || "";
    const city   = cityInput?.value?.toLowerCase() || "";

    if (county === "nairobi" || city.includes("nairobi")) {
      podOption.disabled = false;
      podNote.textContent = "✅ Pay on Delivery is available in Nairobi.";
      podNote.classList.remove("text-muted");
      podNote.classList.add("text-success");
    } else {
      podOption.disabled = true;
      podOption.checked = false;
      podNote.textContent = "🚫 Not available in your location. Please choose another payment method.";
      podNote.classList.remove("text-success");
      podNote.classList.add("text-muted");
    }
  }

  // Run once on page load
  toggleMpesaRequirement();
  togglePOD();

  // Re-run whenever payment method changes
  [mpesaOption, paypalOption, cardOption, podOption].forEach(opt => {
    opt?.addEventListener("change", toggleMpesaRequirement);
  });

  // Re-run whenever county or city changes
  countySelect?.addEventListener("change", togglePOD);
  cityInput?.addEventListener("input", togglePOD);
});

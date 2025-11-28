 document.addEventListener("DOMContentLoaded", function() {
    // Payment toggle
    function setupPaymentToggle(mpesaRadioId, paypalRadioId, paystackRadioId, phoneFieldId) {
      const mpesaRadio   = document.getElementById(mpesaRadioId);
      const paypalRadio  = document.getElementById(paypalRadioId);
      const paystackRadio= document.getElementById(paystackRadioId);
      const phoneField   = document.getElementById(phoneFieldId);

      function togglePhoneField() {
        if (mpesaRadio && mpesaRadio.checked) {
          phoneField.style.display = "block";
        } else if (phoneField) {
          phoneField.style.display = "none";
        }
      }

      [mpesaRadio, paypalRadio, paystackRadio].forEach(radio => {
        if (radio) radio.addEventListener("change", togglePhoneField);
      });

      if (phoneField) phoneField.style.display = "none";
      togglePhoneField();
    }

    // Country toggle
    function setupCountryToggle(countrySelectId, countyWrapperId, regionWrapperId) {
      const countrySelect = document.getElementById(countrySelectId);
      const countyWrapper = document.getElementById(countyWrapperId);
      const regionWrapper = document.getElementById(regionWrapperId);

      if (!countrySelect) return;

      function toggleFields() {
        if (countrySelect.value === "Kenya") {
          countyWrapper.style.display = "block";
          regionWrapper.style.display = "none";
        } else {
          countyWrapper.style.display = "none";
          regionWrapper.style.display = "block";
        }
      }
      countrySelect.addEventListener("change", toggleFields);
      toggleFields();
    }

    // DHL rates
    async function fetchRates(countrySelectId, cityFieldId, ratesBoxId) {
      const countrySelect = document.getElementById(countrySelectId);
      const cityField     = document.getElementById(cityFieldId);
      const ratesBox      = document.getElementById(ratesBoxId);

      if (!countrySelect || !cityField || !ratesBox) return;

      async function getRates() {
        const country = countrySelect.value;
        const city    = cityField.value;
        if (!country || !city) return;

        ratesBox.innerHTML = "Fetching DHL rates...";
        try {
          const response = await fetch(`/shipping/rates?country=${country}&city=${city}`);
          const data = await response.json();
          if (data.error) {
            ratesBox.innerHTML = `<span class="text-danger">${data.error}</span>`;
          } else {
            let html = "<ul class='list-unstyled mb-0'>";
            (data.products || []).forEach(rate => {
              html += `<li><strong>${rate.productName}</strong>: ${rate.totalPrice[0].price} ${rate.totalPrice[0].currency}</li>`;
            });
            html += "</ul>";
            ratesBox.innerHTML = html;
          }
        } catch (error) {
          ratesBox.innerHTML = `<span class="text-danger">Error fetching rates.</span>`;
        }
      }

      countrySelect.addEventListener("change", getRates);
      cityField.addEventListener("blur", getRates);
    }

    // --- Initialize for PRODUCT form ---
    setupPaymentToggle("provider_mpesa_product", "provider_paypal_product", "provider_paystack_product", "mpesa_phone_field_product");
    setupCountryToggle("country-select-product", "county-wrapper-product", "region-wrapper-product");
    fetchRates("country-select-product", "city-field-product", "shipping-rates-product");

    // --- Initialize for CART form ---
    setupPaymentToggle("provider_mpesa_cart", "provider_paypal_cart", "provider_paystack_cart", "mpesa_phone_field_cart");
    setupCountryToggle("country-select-cart", "county-wrapper-cart", "region-wrapper-cart");
    fetchRates("country-select-cart", "city-field-cart", "shipping-rates-cart");
  });

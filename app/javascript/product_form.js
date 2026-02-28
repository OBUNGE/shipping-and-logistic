console.log("product_form.js loaded");

// ============================================================
// EVENT DELEGATION (Outside turbo:load to prevent duplicates)
// ============================================================

const subtotalEl = document.getElementById("subtotal");

function updateSubtotal() {
  let totalKES = 0;
  document.querySelectorAll(".variant-qty").forEach(input => {
    const qty = parseInt(input.value || "0", 10);
    const price = parseFloat(input.dataset.price || "0");
    const variantSubtotalEl = document.getElementById(`subtotal_${input.id}`);
    const subtotalKES = qty * price;

    if (variantSubtotalEl) {
      variantSubtotalEl.textContent = qty > 0 ? `= ${subtotalKES.toFixed(2)} KES` : "";
    }

    totalKES += subtotalKES;
  });

  if (subtotalEl) {
    const usdRate = 0.0075; 
    const totalUSD = totalKES * usdRate;
    subtotalEl.textContent = `Subtotal: ${totalKES.toFixed(2)} KES ≈ ${totalUSD.toFixed(2)} USD`;
  }
}

// ============================================================
// PRICING & PROFIT CALCULATIONS
// ============================================================

function calculateMargin() {
  const costPrice = parseFloat(document.getElementById('product_cost_price')?.value) || 0;
  const sellingPrice = parseFloat(document.getElementById('product_price')?.value) || 0;
  const shippingCost = parseFloat(document.getElementById('product_shipping_cost')?.value) || 0;
  const priceEndingSelect = document.querySelector('[name="product[price_ending]"]');
  const priceEnding = priceEndingSelect?.value || '';
  
  // Calculate profit
  const profit = sellingPrice - costPrice;
  const profitPercent = costPrice > 0 ? ((profit / costPrice) * 100).toFixed(1) : 0;
  
  // Update profit display
  const profitAmountEl = document.getElementById('profit-amount');
  const profitPercentEl = document.getElementById('profit-percent');
  
  if (profitAmountEl) {
    profitAmountEl.textContent = `KES ${profit.toLocaleString()}`;
  }
  if (profitPercentEl) {
    profitPercentEl.textContent = profitPercent;
  }
  
  // Update total cost with shipping
  const totalCost = sellingPrice + shippingCost;
  const totalCostEl = document.getElementById('total-cost');
  if (totalCostEl) {
    totalCostEl.textContent = `KES ${totalCost.toLocaleString()}`;
  }
  
  // Update price preview with psychological pricing
  updatePricePreview(sellingPrice, priceEnding);
}

function updatePricePreview(basePrice, ending) {
  const pricePreviewEl = document.getElementById('price-preview');
  if (!pricePreviewEl) return;
  
  let displayPrice = basePrice;
  
  if (ending && ending !== '') {
    // Remove last 2 digits and add psychological ending
    // e.g., 1200 with "99" ending → 1199
    const baseWithoutEnding = Math.floor(basePrice / 100) * 100;
    displayPrice = baseWithoutEnding + parseInt(ending);
  }
  
  pricePreviewEl.textContent = `KES ${displayPrice.toLocaleString()}`;
}

// Consolidated Click Handler (attached once, never duplicated)
document.addEventListener("click", (e) => {
  // Quantity +/- buttons
  if (e.target.classList.contains("qty-plus") || e.target.classList.contains("qty-minus")) {
    e.preventDefault();
    const targetId = e.target.dataset.target;
    const input = document.getElementById(targetId);
    if (!input) return;

    let value = parseInt(input.value || "0", 10);
    const min = parseInt(input.min || "0", 10);

    if (e.target.classList.contains("qty-plus")) {
      value += 1;
    } else {
      value = Math.max(min, value - 1);
    }

    input.value = value;
    updateSubtotal();
    return;
  }

  // Delete Gallery Image (Persisted)
  if (e.target.classList.contains("delete-gallery-image")) {
    e.preventDefault();
    e.stopPropagation();
    const btn = e.target;
    const url = btn.dataset.url;
    const form = btn.closest("form");
    
    if (!form.querySelector(`input[name='remove_gallery[]'][value='${url}']`)) {
      const hidden = document.createElement("input");
      hidden.type = "hidden";
      hidden.name = "remove_gallery[]";
      hidden.value = url;
      form.appendChild(hidden);
    }
    btn.closest(".gallery-image-block").style.display = "none";
    return;
  }

  // Add Variant
  if (e.target.classList.contains("add-variant-btn")) {
    e.preventDefault();
    e.stopPropagation();
    const container = document.getElementById("variant-fields");
    const template = document.getElementById("variant-template");
    const templateContent = template && template.content ? template.content : template;

    if (templateContent && container) {
      const clone = templateContent.querySelector(".variant-block").cloneNode(true);
      const timestamp = Date.now().toString();
      clone.innerHTML = clone.innerHTML.replace(/NEW_RECORD/g, timestamp);
      clone.dataset.key = timestamp;
      container.appendChild(clone);
      
      // Init dropdown
      clone.querySelectorAll("select[name*='[name]']").forEach(typeSelect => {
        updateValueOptions(typeSelect);
      });
    }
    return;
  }

  // Delete Variant
  if (e.target.classList.contains("delete-variant")) {
    e.preventDefault();
    e.stopPropagation();
    const block = e.target.closest(".variant-block");
    const destroyInput = block.querySelector(".destroy-flag");
    const idInput = block.querySelector("input[name*='[id]']");

    if (idInput && idInput.value && destroyInput) {
      destroyInput.value = "1";
      block.style.display = "none";
    } else {
      block.remove();
    }
    return;
  }

  // Add Variant Image
  if (e.target.classList.contains("add-variant-image-btn")) {
    e.preventDefault();
    e.stopPropagation();
    const block = e.target.closest(".variant-block");
    const imagesWrapper = block.querySelector(".variant-images-wrapper");
    const template = document.getElementById("variant-image-template");
    const templateContent = template && template.content ? template.content : template;

    if (templateContent && imagesWrapper && block) {
      const newImageBlock = templateContent.querySelector(".variant-image-block").cloneNode(true);
      const variantKey = block.dataset.key || Date.now().toString();
      const index = imagesWrapper.querySelectorAll(".variant-image-block").length;

      newImageBlock.querySelectorAll("input, button").forEach(element => {
        if (element.name) {
          element.name = element.name.replace(/INDEX/g, variantKey).replace(/NEW_IMAGE/g, index);
        }
      });
      imagesWrapper.appendChild(newImageBlock);
    }
    return;
  }

  // Delete Variant Image
  if (e.target.classList.contains("delete-variant-image")) {
    e.preventDefault();
    e.stopPropagation();
    const imgBlock = e.target.closest(".variant-image-block");
    const destroyInput = imgBlock.querySelector("input[name*='[_destroy]']");
    const idInput = imgBlock.querySelector("input[name*='[id]']");

    if (idInput && idInput.value && destroyInput) {
      destroyInput.value = "1";
      imgBlock.style.display = "none";
    } else {
      imgBlock.remove();
    }
    return;
  }
});

// Consolidated Input Handler (attached once, never duplicated)
document.addEventListener("input", (e) => {
  if (e.target.classList.contains("variant-qty")) {
    updateSubtotal();
  }
  
  // Real-time pricing calculations
  if (e.target.id === "product_cost_price" || 
      e.target.id === "product_price" || 
      e.target.id === "product_shipping_cost") {
    calculateMargin();
  }
});

// Consolidated Change Handler (attached once, never duplicated)
document.addEventListener("change", (e) => {
  if (e.target.matches("select[name*='[name]']")) {
    updateValueOptions(e.target);
  }
  if (e.target.matches("input[type='file'][name*='[image]']")) {
    previewVariantImage(e);
  }
  
  // Pricing dropdown change
  if (e.target.matches('[name="product[price_ending]"]')) {
    calculateMargin();
  }
});

// Use turbo:load so bindings re-apply after Turbo Stream updates
document.addEventListener("turbo:load", () => {
  // -----------------------------
  // Floating WhatsApp Chat Button
  // -----------------------------
  const existingBanner = document.getElementById("whatsapp-floating-chat");
  if (!existingBanner) {
    const banner = document.createElement("div");
    banner.id = "whatsapp-floating-chat";
    banner.innerHTML = '<img src="/assets/whatsapp.png" alt="WhatsApp" style="width:24px;height:24px;vertical-align:middle;margin-right:8px;">';

    banner.style.position = "fixed";
    banner.style.bottom = "10px";
    banner.style.right = "10px";
    banner.style.background = "#25D366"; // WhatsApp green
    banner.style.color = "white";
    banner.style.padding = "10px 15px";
    banner.style.borderRadius = "25px";
    banner.style.fontWeight = "bold";
    banner.style.cursor = "pointer";
    banner.style.boxShadow = "0 2px 6px rgba(0,0,0,0.2)";
    banner.style.zIndex = 9999;

    banner.onclick = () => {
      window.open("https://wa.me/+254726565342", "_blank");
    };

    document.body.appendChild(banner);
  }

  // --------------------------
  // 2. Main Image Preview
  // --------------------------
  window.previewMainImage = function(event) {
    const output = document.getElementById("main-image-preview");
    const file = event.target.files[0];
    if (!output) return;
    if (file) {
      output.src = URL.createObjectURL(file);
      output.onload = () => URL.revokeObjectURL(output.src);
      output.style.display = "block";
    } else {
      output.src = "";
      output.style.display = "none";
    }
  };

  // --------------------------
  // 3. Gallery Preview + Drag/Drop
  // --------------------------
  const galleryPreview = document.getElementById("gallery-preview");
  const galleryInputs = document.getElementById("gallery-inputs");

  window.previewGalleryImages = function(event) {
    if (!galleryPreview) return;
    galleryPreview.innerHTML = "";
    Array.from(event.target.files).forEach((file) => {
      const reader = new FileReader();
      reader.onload = e => {
        const wrapper = document.createElement("div");
        wrapper.className = "col-md-3 mb-2 text-center preview-item";
        wrapper.draggable = true;

        const img = document.createElement("img");
        img.src = e.target.result;
        img.className = "img-thumbnail";
        img.style.maxHeight = "150px";

        const removeBtn = document.createElement("button");
        removeBtn.className = "btn btn-sm btn-outline-danger mt-2";
        removeBtn.textContent = "Remove";
        removeBtn.type = "button"; // Important: prevent form submit
        removeBtn.addEventListener("click", () => wrapper.remove());

        wrapper.appendChild(img);
        wrapper.appendChild(removeBtn);
        galleryPreview.appendChild(wrapper);
      };
      reader.readAsDataURL(file);
    });
  };

  window.addGalleryInput = function() {
    if (!galleryInputs) return;
    const input = document.createElement("input");
    input.type = "file";
    input.name = "gallery_images[]";
    input.accept = "image/*";
    input.className = "form-control form-control-sm mb-2";
    input.onchange = window.previewGalleryImages;
    galleryInputs.appendChild(input);
  };

  // --------------------------
  // 4. Category → Subcategory AJAX
  // --------------------------
  const categorySelect = document.getElementById("category-select");
  const subcategorySelect = document.getElementById("subcategory-select");

  if (categorySelect && subcategorySelect) {
    categorySelect.addEventListener("change", e => {
      const categoryId = e.target.value;
      fetch(`/categories/${categoryId}/subcategories.json`)
        .then(res => res.json())
        .then(data => {
          subcategorySelect.innerHTML = "<option value=''>Select a subcategory</option>";
          data.forEach(sub => {
            const option = document.createElement("option");
            option.value = sub.id;
            option.textContent = sub.name;
            subcategorySelect.appendChild(option);
          });
        });
    });
  }

  // === Quantity & Subtotal Logic ===
  // Initial calculation on page load
  updateSubtotal();

  // Initialize existing variant selects
  document.querySelectorAll("select[name*='[name]']").forEach(typeSelect => {
    updateValueOptions(typeSelect);
  });

  // =============================
  // Initialize Pricing Calculations
  // =============================
  calculateMargin();
});

// ============================================================
// HELPER FUNCTIONS (Outside turbo:load, reusable)
// ============================================================

const typeOptions = {
  Color: ["Black", "Brown", "Tan", "Cognac", "Navy", "White"],
  BagSize: ["Small", "Medium", "Large"],
  ShoeSize: ["38", "39", "40", "41", "42", "43", "44"], // EU sizes
  BeltSize: ["XS", "S", "M", "L", "XL"],
  Material: ["Full-Grain Leather", "Top-Grain Leather", "Suede", "Patent Leather"],
  Finish: ["Matte", "Glossy", "Textured"],
  Packaging: ["Dust Bag", "Gift Box", "Eco Pouch"]
};

function updateValueOptions(typeSelect) {
  const selected = typeSelect.value;
  const block = typeSelect.closest(".variant-block");
  const valueSelect = block.querySelector("select[name*='[value]']");
  if (!valueSelect) return;

  valueSelect.innerHTML = "";
  const options = typeOptions[selected] || [];
  
  const promptOption = document.createElement("option");
  promptOption.value = "";
  promptOption.textContent = "Select option";
  valueSelect.appendChild(promptOption);

  options.forEach(opt => {
    const option = document.createElement("option");
    option.value = opt;
    option.textContent = opt;
    valueSelect.appendChild(option);
  });

  const savedValue = valueSelect.dataset.current || block.dataset.savedValue;
  if (savedValue) {
    const match = Array.from(valueSelect.options).find(o => o.value === savedValue);
    if (match) valueSelect.value = savedValue;
  }

  const actions = block.querySelector(".color-image-actions");
  if (actions) actions.classList.toggle("d-none", selected !== "Color");
}

// Preview Variant Image (Helper)
window.previewVariantImage = function(event) {
  const file = event.target.files[0];
  if (!file) return;

  const block = event.target.closest(".variant-image-block");
  if (!block) return;

  let preview = block.querySelector(".variant-image-preview");
  if (!preview) {
    preview = document.createElement("img");
    preview.className = "img-thumbnail mb-2 variant-image-preview";
    preview.style.maxHeight = "150px";
    event.target.insertAdjacentElement("beforebegin", preview);
  }

  const blobUrl = URL.createObjectURL(file);
  preview.src = blobUrl;
  preview.style.display = "block"; 
  preview.onload = () => URL.revokeObjectURL(blobUrl);
};
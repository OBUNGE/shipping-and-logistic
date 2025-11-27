console.log("product_form.js loaded");

// Use turbo:load so bindings re-apply after Turbo Stream updates
document.addEventListener("turbo:load", () => {
  // -----------------------------
  // Floating WhatsApp Chat Button
  // -----------------------------
  const banner = document.createElement("div");
  banner.innerHTML = '<img src="/assets/whatsapp.png" alt="WhatsApp" style="width:24px;height:24px;vertical-align:middle;margin-right:8px;"> Chat on WhatsApp';

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

  // Make it clickable → opens WhatsApp chat
  banner.onclick = () => {
    window.open("https://wa.me/+254726565342", "_blank");
  };

  document.body.appendChild(banner);



  // -----------------------------
  // 1. Price + Shipping Total
  // -----------------------------
  const priceField = document.getElementById("product_price");
  const shippingField = document.getElementById("product_shipping_cost");
  const totalCostSpan = document.getElementById("total-cost");

  const updateTotal = () => {
    const price = parseFloat(priceField?.value) || 0;
    const shipping = parseFloat(shippingField?.value) || 0;
    // NOTE: If you need to format this using the Ruby 'display_price' function, 
    // you might need to use a Turbo Stream endpoint for formatting, or port the logic to JS.
    if (totalCostSpan) totalCostSpan.textContent = `KES ${(price + shipping).toFixed(2)}`;
  };

  priceField?.addEventListener("input", updateTotal);
  shippingField?.addEventListener("input", updateTotal);
  updateTotal(); // Run once on load to ensure total is correct

  // -----------------------------
  // 2. Main Image Preview
  // -----------------------------
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

  // -----------------------------
  // 3. Gallery Preview + Drag/Drop
  // -----------------------------
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
    input.name = "gallery_images[]"; // Use the correct name from your form (gallery_images[])
    input.accept = "image/*";
    input.className = "form-control form-control-sm mb-2";
    input.onchange = window.previewGalleryImages;
    galleryInputs.appendChild(input);
  };

  if (galleryPreview) {
    let dragged;
    galleryPreview.addEventListener("dragstart", e => {
      dragged = e.target.closest(".preview-item");
      if (dragged) dragged.style.opacity = 0.5;
    });
    galleryPreview.addEventListener("dragend", () => {
      if (dragged) dragged.style.opacity = "";
    });
    galleryPreview.addEventListener("dragover", e => e.preventDefault());
    galleryPreview.addEventListener("drop", e => {
      e.preventDefault();
      const target = e.target.closest(".preview-item");
      if (target && dragged && dragged !== target) {
        galleryPreview.insertBefore(dragged, target);
      }
    });
  }

  // -----------------------------
  // 4. Category → Subcategory AJAX
  // -----------------------------
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

// -----------------------------
// 5. added live subtotal
// -----------------------------
  

document.addEventListener("DOMContentLoaded", () => {
  const subtotalEl = document.getElementById("subtotal");

  function updateSubtotal() {
    let totalKES = 0;
    document.querySelectorAll(".variant-qty").forEach(input => {
      const qty = parseInt(input.value || "0", 10);
      const price = parseFloat(input.dataset.price || "0");
      const variantSubtotalEl = document.getElementById(`subtotal_${input.id}`);
      const subtotalKES = qty * price;

      // update per-variant subtotal
      if (variantSubtotalEl) {
        variantSubtotalEl.textContent = qty > 0 ? `= ${subtotalKES.toFixed(2)} KES` : "";
      }

      totalKES += subtotalKES;
    });

    if (subtotalEl) {
      const usdRate = 0.0075; // Example: 1 KES ≈ 0.0075 USD
      const totalUSD = totalKES * usdRate;
      subtotalEl.textContent = `Subtotal: ${totalKES.toFixed(2)} KES ≈ ${totalUSD.toFixed(2)} USD`;
    }
  }

  // Bind plus/minus buttons
  document.addEventListener("click", (e) => {
    if (e.target.classList.contains("qty-plus") || e.target.classList.contains("qty-minus")) {
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
    }
  });

  // Bind manual typing
  document.addEventListener("input", (e) => {
    if (e.target.classList.contains("variant-qty")) {
      updateSubtotal();
    }
  });

  // Initialize subtotal on page load
  updateSubtotal();
});





// -----------------------------
// 5. variant add to cart button
// -----------------------------

document.addEventListener("click", (e) => {
  if (e.target.classList.contains("qty-plus") || e.target.classList.contains("qty-minus")) {
    const targetId = e.target.dataset.target;
    const input = document.getElementById(targetId);
    if (!input) return;

    let value = parseInt(input.value || "0", 10);
    const min = parseInt(input.min || "0", 10);

    if (e.target.classList.contains("qty-plus")) {
      value += 1;
    } else if (e.target.classList.contains("qty-minus")) {
      value = Math.max(min, value - 1);
    }

    input.value = value;
  }
});


// -----------------------------
// 5. product image page
// -----------------------------
document.addEventListener("DOMContentLoaded", () => {
  const carousel = document.getElementById("productCarousel");
  if (!carousel) return;

  const thumbnails = document.querySelectorAll("[data-bs-target='#productCarousel'][data-bs-slide-to]");

  // Sync active thumbnail
  carousel.addEventListener("slid.bs.carousel", (e) => {
    const activeIndex = e.to;
    thumbnails.forEach((thumb, idx) => {
      if (idx === activeIndex) {
        thumb.classList.add("active-thumb");
      } else {
        thumb.classList.remove("active-thumb");
      }
    });
  });

  // Scroll arrows
  const scrollContainer = document.querySelector(".thumbnail-scroll");
  const leftBtn = document.querySelector(".thumb-scroll-btn.left");
  const rightBtn = document.querySelector(".thumb-scroll-btn.right");

  if (scrollContainer && leftBtn && rightBtn) {
    leftBtn.addEventListener("click", () => {
      scrollContainer.scrollBy({ left: -150, behavior: "smooth" });
    });
    rightBtn.addEventListener("click", () => {
      scrollContainer.scrollBy({ left: 150, behavior: "smooth" });
    });
  }
});





// -----------------------------
// 5. Preview Variant Image
// -----------------------------
window.previewVariantImage = function(event) {
  const file = event.target.files[0];
  if (!file) return;

  // find the variant image block wrapper
  const block = event.target.closest(".variant-image-block");
  if (!block) return; // safety guard

  // find or create preview img
  let preview = block.querySelector(".variant-image-preview");
  if (!preview) {
    preview = document.createElement("img");
    preview.className = "img-thumbnail mb-2 variant-image-preview";
    preview.style.maxHeight = "150px";
    event.target.insertAdjacentElement("beforebegin", preview);
  }

  // show preview using blob URL
  const blobUrl = URL.createObjectURL(file);
  preview.src = blobUrl;
  preview.style.display = "block"; // 🔑 ensure it's visible

  // clean up blob URL after load
  preview.onload = () => URL.revokeObjectURL(blobUrl);
};

// -----------------------------
// 6. Variant Value Auto-Populate + Toggle Image Upload
// -----------------------------
const typeOptions = {
  Color: ["Black","Blue","Red","Green","White"],
  Size: ["XS","S","M","L","XL","XXL"],
  Storage: ["64GB","128GB","256GB","512GB","1TB"],
  Material: ["Cotton","Leather","Polyester","Plastic","Metal","Wood"],
  Packaging: ["Box","Bag","Sachet","Envelope","Bottle","Jar"]
};

function updateValueOptions(typeSelect) {
  const selected = typeSelect.value;
  const block = typeSelect.closest(".variant-block");
  const valueSelect = block.querySelector("select[name*='[value]']");
  if (!valueSelect) return;

  // clear and repopulate
  valueSelect.innerHTML = "";
  const options = typeOptions[selected] || [];
  
  // Add prompt option
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

  // ✅ auto-select saved value if present
  const savedValue = valueSelect.dataset.current || block.dataset.savedValue;
  if (savedValue) {
    const match = Array.from(valueSelect.options).find(o => o.value === savedValue);
    if (match) valueSelect.value = savedValue;
  }

  const actions = block.querySelector(".color-image-actions");
  if (actions) actions.classList.toggle("d-none", selected !== "Color");
}

// On change binding (for selects)
document.addEventListener("change", (e) => {
  if (e.target.matches("select[name*='[name]']")) {
    updateValueOptions(e.target);
  }
});

// Run once on page load for existing selects
document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("select[name*='[name]']").forEach(typeSelect => {
    updateValueOptions(typeSelect);
  });
});

// -----------------------------
// 7. Delete gallery images (persisted)
// -----------------------------
document.addEventListener("click", (e) => {
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
  }
});

// -----------------------------
// 8. Preview file inputs auto-bind (generic)
// -----------------------------
document.addEventListener("change", (e) => {
  if (e.target.matches("input[type='file'][name*='[image]']")) {
    previewVariantImage(e);
  }
});

// -----------------------------
// 9. Add / Delete Variants & Images
// -----------------------------
document.addEventListener("click", (e) => {
  // ➕ Add Variant
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

      clone.querySelectorAll("select[name*='[name]']").forEach(typeSelect => {
        updateValueOptions(typeSelect);
      });
    }
  }

  // ❌ Delete Variant
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
  }

  // ➕ Add Variant Image
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
  }

  // ❌ Delete Variant Image
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
  }
});


});
console.log("product_form.js loaded");

// Use turbo:load so bindings re‑apply after Turbo Stream updates
document.addEventListener("turbo:load", () => {
  // -----------------------------
  // Debug banner
  // -----------------------------
  const banner = document.createElement("div");
  banner.textContent = "felix omondi odhiambo";
  banner.style.position = "fixed";
  banner.style.bottom = "10px";
  banner.style.right = "10px";
  banner.style.background = "brown";
  banner.style.color = "black";
  banner.style.padding = "5px 10px";
  banner.style.zIndex = 9999;
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
    if (totalCostSpan) totalCostSpan.textContent = `KES ${(price + shipping).toFixed(2)}`;
  };

  priceField?.addEventListener("input", updateTotal);
  shippingField?.addEventListener("input", updateTotal);

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
    input.name = "product[gallery_images][]";
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
  // 5. Variant Image Preview
  // -----------------------------
  window.previewVariantImage = function(event) {
    const file = event.target.files[0];
    if (!file) return;

    const preview = document.createElement("img");
    preview.src = URL.createObjectURL(file);
    preview.className = "img-thumbnail mt-2";
    preview.style.maxHeight = "150px";

    event.target.insertAdjacentElement("afterend", preview);
    preview.onload = () => URL.revokeObjectURL(preview.src);
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

    console.log("updateValueOptions fired. Selected:", selected);

    valueSelect.innerHTML = "";
    const options = typeOptions[selected] || [];
    options.forEach(opt => {
      const option = document.createElement("option");
      option.value = opt;
      option.textContent = opt;
      valueSelect.appendChild(option);
    });

    const actions = block.querySelector(".color-image-actions");
    if (actions) {
      if (selected === "Color") {
        actions.classList.remove("d-none");
      } else {
        actions.classList.add("d-none");
      }
    }
  }

  document.querySelectorAll("select[name*='[name]']").forEach(typeSelect => {
    updateValueOptions(typeSelect); // populate on load
    typeSelect.addEventListener("change", () => updateValueOptions(typeSelect));
  });

  // -----------------------------
  // 7. Delete Gallery Images (persisted)
  // -----------------------------
  function bindDeleteButtons(container) {
    container.querySelectorAll(".delete-gallery-image").forEach(btn => {
      btn.removeEventListener("click", btn._handler);
      btn._handler = () => {
        const url = btn.dataset.url;
        const form = btn.closest("form");
        const hidden = document.createElement("input");
        hidden.type = "hidden";
        hidden.name = "remove_gallery[]";
        hidden.value = url;
        form.appendChild(hidden);
        btn.closest(".gallery-image-block").style.display = "none";
      };
      btn.addEventListener("click", btn._handler);
    });
  }

  bindDeleteButtons(document);
// -----------------------------
// 9. Add new variant dynamically (before save)
// -----------------------------
document.addEventListener("click", (e) => {
  // ➕ Add Variant
  if (e.target.classList.contains("add-variant-btn")) {
    const container = document.getElementById("variant-fields");
    const template = document.getElementById("variant-template");

    if (template && container) {
      const clone = template.firstElementChild.cloneNode(true);

      // Unique timestamp for nested attributes
      const timestamp = new Date().getTime();
      clone.innerHTML = clone.innerHTML
        .replace(/NEW_RECORD/g, timestamp)
        .replace(/NEW_IMAGE/g, timestamp + "_img");

      // Enable all disabled inputs/selects
      clone.querySelectorAll("[disabled]").forEach((el) =>
        el.removeAttribute("disabled")
      );

      container.appendChild(clone);
    }
  }

  // ❌ Delete Variant
  if (e.target.classList.contains("delete-variant")) {
    e.preventDefault();
    e.target.closest(".variant-block").remove();
  }

  // ➕ Add Variant Image
  if (e.target.classList.contains("add-variant-image-btn")) {
    const block = e.target.closest(".variant-block");
    const container = block.querySelector(".color-image-actions");
    const template = document.getElementById("variant-image-template");

    if (template && container) {
      const clone = template.firstElementChild.cloneNode(true);

      const timestamp = new Date().getTime();
      clone.innerHTML = clone.innerHTML
        .replace(/NEW_RECORD/g, timestamp)
        .replace(/NEW_IMAGE/g, timestamp + "_img");

      // Enable all disabled inputs/selects
      clone.querySelectorAll("[disabled]").forEach((el) =>
        el.removeAttribute("disabled")
      );

      container.insertBefore(clone, e.target);
    }
  }

  // ❌ Delete Variant Image
  if (e.target.classList.contains("delete-variant-image")) {
    e.preventDefault();
    e.target.closest(".variant-image-block").remove();
  }
}); // ✅ properly closed

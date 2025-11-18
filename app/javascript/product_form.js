// app/javascript/product_form.js
console.log("product_form.js loaded ✅")

document.addEventListener("turbo:load", () => {
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
    Array.from(event.target.files).forEach((file, idx) => {
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

  // Drag & drop for gallery preview
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
  // 5. Variant / Inventory Dynamic Fields
  // -----------------------------
  const typeOptions = {
    Size: ["XS","S","M","L","XL","XXL","3XL","4XL","5XL","6XL","7XL","8XL","9XL","10XL"],
    Color: ["Red","Blue","Black","White","Green","Yellow","Purple","Orange","Pink","Gray","Brown","Cyan","Magenta","Lime","Teal","Navy","Maroon","Olive","Silver","Gold","Beige"],
    Material: ["Cotton","Leather","Polyester","Plastic","Metal","Wood","Glass","Silk","Wool","Denim"],
    Storage: ["64GB","128GB","256GB","512GB","1TB","2TB","4TB"],
    Packaging: ["Box","Bag","Sachet","Envelope","Bottle","Jar"]
  };

  function updateValueOptions(typeSelect) {
    const selected = typeSelect.value;
    const block = typeSelect.closest(".variant-block");
    const valueSelect = block.querySelector(".variant-value");
    const actions = block.querySelector(".color-image-actions");
    if (!valueSelect) return;

    valueSelect.innerHTML = "";
    const options = typeOptions[selected] || [];
    options.forEach(opt => {
      const option = document.createElement("option");
      option.value = opt;
      option.textContent = opt;
      valueSelect.appendChild(option);
    });

    // Show image upload if Color
    if (actions) actions.classList.toggle("d-none", selected !== "Color");
  }

  function bindVariantDropdowns(container) {
    container.querySelectorAll(".variant-type").forEach(sel => {
      updateValueOptions(sel);
      sel.addEventListener("change", () => updateValueOptions(sel));
    });
  }

  function bindDeleteButtons(container) {
    container.querySelectorAll(".delete-variant").forEach(btn => {
      btn.removeEventListener("click", btn._handler);
      btn._handler = () => {
        const block = btn.closest(".variant-block");
        block.querySelector("input.destroy-flag").value = "true";
        block.style.display = "none";
      };
      btn.addEventListener("click", btn._handler);
    });

    container.querySelectorAll(".delete-variant-image").forEach(btn => {
      btn.removeEventListener("click", btn._handler);
      btn._handler = () => {
        const block = btn.closest(".variant-image-block");
        block.querySelector("input.destroy-flag").value = "true";
        block.style.display = "none";
      };
      btn.addEventListener("click", btn._handler);
    });

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

  function addVariantImageToBlock(variantBlock) {
    const template = document.getElementById("variant-image-template").innerHTML;
    const parentInput = variantBlock.querySelector("input[name*='variants_attributes']");
    const parentIdMatch = parentInput?.name.match(/variants_attributes\]\[(new_\d+|\d+)\]/);
    const parentId = parentIdMatch ? parentIdMatch[1] : `new_${Date.now()}`;
    const uniqueImageId = `new_${Date.now()}`;
    const html = template.replace(/NEW_RECORD/g, parentId).replace(/NEW_IMAGE/g, uniqueImageId);

    const wrapper = document.createElement("div");
    wrapper.innerHTML = html.trim();
    const block = wrapper.firstElementChild;
    variantBlock.querySelector(".color-image-actions").append(block);

    bindDeleteButtons(block);
  }

  function bindAddImageButtons(container) {
    container.querySelectorAll(".add-variant-image-btn").forEach(btn => {
      btn.removeEventListener("click", btn._handler);
      btn._handler = () => {
        const block = btn.closest(".variant-block");
        addVariantImageToBlock(block);
      };
      btn.addEventListener("click", btn._handler);
    });
  }

  window.addFields = function(containerId) {
    const container = document.getElementById(containerId);
    const template = document.getElementById(containerId.replace("-fields", "-template")).innerHTML;
    const unique = `new_${Date.now()}`;
    const html = template.replace(/NEW_RECORD/g, unique);

    const wrapper = document.createElement("div");
    wrapper.innerHTML = html.trim();
    container.append(wrapper.firstElementChild);

    bindVariantDropdowns(container.lastElementChild);
    bindDeleteButtons(container.lastElementChild);
    bindAddImageButtons(container.lastElementChild);
  };

  // Initial binding
  bindVariantDropdowns(document);
  bindDeleteButtons(document);
  bindAddImageButtons(document);
});

// -----------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------
// End of app/javascript/product_form.js
// -----------------------------------------------------------------------------------------------------
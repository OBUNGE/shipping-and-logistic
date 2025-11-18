console.log("product_form.js loaded ✅")

// ----------------------------------------------------
// GLOBAL FUNCTIONS (Used by onclick attributes in ERB)
// ----------------------------------------------------

/**
 * Generic function to add a field by cloning a hidden template.
 * Used for Inventory fields.
 */
window.addFields = function(containerId) {
  const container = document.getElementById(containerId);
  const templateId = containerId.replace("-fields", "-template");
  const template = document.getElementById(templateId)?.innerHTML;
  if (!container || !template) return;

  const uniqueId = `new_${Date.now()}`;
  // Replace the placeholder NEW_RECORD in the template with a unique ID
  const newBlockHtml = template.replace(/NEW_RECORD/g, uniqueId);

  const wrapper = document.createElement("div");
  wrapper.innerHTML = newBlockHtml.trim();
  const newBlock = wrapper.firstElementChild;
  if (newBlock) {
    container.appendChild(newBlock);
  }
};

/**
 * Function specifically for adding a Variant block.
 * CRITICAL: It must re-bind the change listener and delete logic.
 */
window.addVariant = function() {
  const container = document.getElementById("variant-fields");
  const template = document.getElementById("variant-template")?.innerHTML;
  if (!container || !template) return;

  const uniqueId = `new_${Date.now()}`;
  const newBlockHtml = template.replace(/NEW_RECORD/g, uniqueId);

  const wrapper = document.createElement("div");
  wrapper.innerHTML = newBlockHtml.trim();
  const newBlock = wrapper.firstElementChild;
  if (newBlock) {
    container.appendChild(newBlock);

    // Re-bind change listener for Type -> Value auto-populate and image toggle
    const typeSelect = newBlock.querySelector("select[name*='[name]']");
    if (typeSelect) {
      // 1. Initial population based on default (if any) or first option
      updateValueOptions(typeSelect); 
      // 2. Add change listener for future updates
      typeSelect.addEventListener("change", () => updateValueOptions(typeSelect));
    }
    // Re-bind delete logic for the new unsaved variant
    bindDeleteVariant(newBlock);
    // Re-bind the "Add color image" button
    bindAddVariantImageButton(newBlock);
  }
};

/**
 * Function to add a new Variant Image field block to a specific Variant.
 */
window.addVariantImageToBlock = function(variantBlock) {
  const actionsContainer = variantBlock.querySelector(".color-image-actions");
  const templateHtml = document.getElementById("variant-image-template")?.innerHTML;
  if (!actionsContainer || !templateHtml) return;

  // Find the parent variant's unique ID from its input field name
  const parentInputName = variantBlock.querySelector("select[name*='[name]']")?.name;
  const parentIdMatch = parentInputName.match(/variants_attributes\]\[([^\]]+)\]/);
  if (!parentIdMatch) {
    console.error("Could not determine parent variant ID for image template.");
    return;
  }
  const parentId = parentIdMatch[1];
  const uniqueImageId = `new_${Date.now()}`;

  // Replace placeholders in the image template
  const html = templateHtml
    .replace(/NEW_RECORD/g, parentId) // Uses parent variant ID
    .replace(/NEW_IMAGE/g, uniqueImageId); // Uses unique image ID

  const wrapper = document.createElement("div");
  wrapper.innerHTML = html.trim();
  const imageBlock = wrapper.firstElementChild;

  if (imageBlock) {
    // Insert the new image block before the "Add color image" button
    const addButton = actionsContainer.querySelector(".add-variant-image-btn");
    actionsContainer.insertBefore(imageBlock, addButton);
    // Re-bind delete logic for the new unsaved variant image
    bindDeleteVariantImage(imageBlock);
  }
};

// ----------------------------------------------------
// BINDING FUNCTIONS (Used inside DOMContentLoaded)
// ----------------------------------------------------

/**
 * Binds the click event to the "Add color image" button within a container (or document).
 */
function bindAddVariantImageButton(container) {
  container.querySelectorAll(".add-variant-image-btn").forEach(btn => {
    // Clone and replace to remove any previously bound events, ensuring clean re-binding
    const newBtn = btn.cloneNode(true); 
    btn.parentNode.replaceChild(newBtn, btn);

    newBtn.addEventListener("click", (e) => {
      const variantBlock = e.target.closest(".variant-block");
      window.addVariantImageToBlock(variantBlock);
    });
  });
}

/**
 * Binds JS delete button logic for UNPERSISTED (new) variants.
 * Sets the hidden _destroy field and hides the block.
 */
function bindDeleteVariant(container) {
  container.querySelectorAll(".delete-variant").forEach(btn => {
    btn.addEventListener("click", () => {
      const variantBlock = btn.closest(".variant-block");
      const destroyField = variantBlock.querySelector(".destroy-flag");
      
      if (destroyField) {
        destroyField.value = "true";
      }
      variantBlock.style.display = "none";
    });
  });
}

/**
 * Binds JS delete button logic for UNPERSISTED (new) variant images.
 * Sets the hidden _destroy field and hides the block.
 */
function bindDeleteVariantImage(container) {
  container.querySelectorAll(".delete-variant-image").forEach(btn => {
    btn.addEventListener("click", () => {
      const imageBlock = btn.closest(".variant-image-block");
      const destroyField = imageBlock.querySelector(".destroy-flag");
      
      if (destroyField) {
        destroyField.value = "true";
      }
      imageBlock.style.display = "none";
    });
  });
}


// ----------------------------------------------------
// DOM CONTENT LOADED
// ----------------------------------------------------

document.addEventListener("DOMContentLoaded", () => {
  // -----------------------------
  // Debug banner
  // -----------------------------
  const banner = document.createElement("div");
  banner.textContent = "felix omondi odhiambo";
  banner.style.position = "fixed";
  banner.style.bottom = "10px";
  banner.style.right = "10px";
  banner.style.background = "yellow";
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

  // Note: This function is defined inside DOMContentLoaded but used globally after the fact
  function updateValueOptions(typeSelect) {
    const selected = typeSelect.value;
    const block = typeSelect.closest(".variant-block");
    const valueSelect = block.querySelector("select[name*='[value]']");
    if (!valueSelect) return;

    // Debug log
    console.log("updateValueOptions fired. Selected:", selected);

    // Populate options
    valueSelect.innerHTML = "<option value=''>Select Option</option>"; // Add placeholder back
    const options = typeOptions[selected] || [];
    options.forEach(opt => {
      const option = document.createElement("option");
      option.value = opt;
      option.textContent = opt;
      valueSelect.appendChild(option);
    });

    // Toggle image upload block visibility
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
  // 8. Bind Dynamic Variant/Image Deletion (for existing unsaved blocks)
  // -----------------------------
  bindDeleteVariant(document);
  bindDeleteVariantImage(document);
  bindAddVariantImageButton(document);
});
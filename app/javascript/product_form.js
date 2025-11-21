console.log("product_form.js loaded");

// Use turbo:load so bindings re-apply after Turbo Stream updates
document.addEventListener("turbo:load", () => {
  // -----------------------------
  // Debug banner (Keep or remove as needed)
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
  // 5. Preview Variant Image
  // -----------------------------
  window.previewVariantImage = function(event) {
    const file = event.target.files[0];
    if (!file) return;

    // find/create preview img
    let preview = event.target.closest(".variant-image-block").querySelector(".variant-image-preview");
    if (!preview) {
      preview = document.createElement("img");
      preview.className = "img-thumbnail mb-2 variant-image-preview";
      preview.style.maxHeight = "150px";
      event.target.insertAdjacentElement("beforebegin", preview);
    }
    preview.src = URL.createObjectURL(file);

    // Update hidden image_url field (temporary blob until backend uploads)
    const hiddenUrlField = event.target.closest(".variant-image-block").querySelector("input[name*='[image_url]']");
    if (hiddenUrlField) hiddenUrlField.value = preview.src;

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
      // only set if the option exists
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
      
      // Check if hidden input already exists to prevent duplicates
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
    // ➕ Add Variant (client-side only for new products)
    if (e.target.classList.contains("add-variant-btn")) {
      e.preventDefault();
      e.stopPropagation();

      const container = document.getElementById("variant-fields");
      const template = document.getElementById("variant-template");

      // Check if template exists AND it's a <template> tag or a known wrapper
      const templateContent = template && template.content ? template.content : template;

      if (templateContent && container) {
        // clone template content
        const clone = templateContent.querySelector(".variant-block").cloneNode(true);

        const timestamp = Date.now().toString();
        // replace NEW_RECORD placeholders in inner HTML names and dataset
        clone.innerHTML = clone.innerHTML.replace(/NEW_RECORD/g, timestamp);
        clone.dataset.key = timestamp;

        // append
        container.appendChild(clone);

        // run initializations (populate value select etc)
        clone.querySelectorAll("select[name*='[name]']").forEach(typeSelect => {
          updateValueOptions(typeSelect);
        });
      }
    }

    // ❌ Delete Variant (Mark for destruction or remove unsaved)
    if (e.target.classList.contains("delete-variant")) {
      e.preventDefault();
      e.stopPropagation();
      const block = e.target.closest(".variant-block");
      const destroyInput = block.querySelector(".destroy-flag");
      const idInput = block.querySelector("input[name*='[id]']"); // Check if it's a persisted record

      if (idInput && idInput.value && destroyInput) {
        // If it has a Rails ID (persisted), mark it and hide.
        destroyInput.value = "1";
        block.style.display = "none";
      } else {
        // If it's a new record added client-side, just remove it.
        block.remove();
      }
    }

    // ➕ Add Variant Image (create fresh block from global template)
    if (e.target.classList.contains("add-variant-image-btn")) {
      e.preventDefault();
      e.stopPropagation();

      const block = e.target.closest(".variant-block");
      const imagesWrapper = block.querySelector(".variant-images-wrapper");
      const template = document.getElementById("variant-image-template");
      const templateContent = template && template.content ? template.content : template;


      if (templateContent && imagesWrapper && block) {
        // create fresh HTML
        const newImageBlock = templateContent.querySelector(".variant-image-block").cloneNode(true);

        // variantKey: numeric or timestamp used in names
        const variantKey = block.dataset.key || Date.now().toString();

        // index for NEW_IMAGE (use length to keep simple)
        const index = imagesWrapper.querySelectorAll(".variant-image-block").length;

        // replace INDEX with variantKey and NEW_IMAGE with index inside names
        newImageBlock.querySelectorAll("input, button").forEach(element => {
          if (element.name) {
            element.name = element.name.replace(/INDEX/g, variantKey).replace(/NEW_IMAGE/g, index);
          }
        });

        // ✅ append safely into wrapper
        imagesWrapper.appendChild(newImageBlock);
      }
    }

    // ❌ Delete Variant Image (Mark for destruction or remove unsaved)
    if (e.target.classList.contains("delete-variant-image")) {
      e.preventDefault();
      e.stopPropagation();

      const imgBlock = e.target.closest(".variant-image-block");
      const destroyInput = imgBlock.querySelector("input[name*='[_destroy]']");
      const idInput = imgBlock.querySelector("input[name*='[id]']"); // Check if it's a persisted record

      if (idInput && idInput.value && destroyInput) {
        // If it has a Rails ID (persisted), mark it and hide.
        destroyInput.value = "1";
        imgBlock.style.display = "none";
      } else {
        // If it's a new file input for a new record, just remove the element.
        imgBlock.remove();
      }
    }
  });


});
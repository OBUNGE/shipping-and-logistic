// product_form.js
console.log("product_form.js loaded");

/*
  Behaviour:
  - Turbo streams render server additions (edit flow).
  - For new product, client-side cloning of templates works.
  - add-variant-image-btn works both client-side (new) and server-side (edit).
  - No unsafe insertBefore usage.
*/

document.addEventListener("turbo:load", initProductForm);
document.addEventListener("DOMContentLoaded", initProductForm);

function initProductForm() {
  bindPriceShipping();
  bindCategoryAjax();
  bindVariantBehaviour();
  bindGallery();
}

/* 1. Price + shipping total */
function bindPriceShipping(){
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
}

/* 2. Category -> subcategory AJAX */
function bindCategoryAjax(){
  const categorySelect = document.getElementById("category-select");
  const subcategorySelect = document.getElementById("subcategory-select");
  if (!categorySelect || !subcategorySelect) return;
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
      }).catch(err => console.error("Subcategory fetch failed", err));
  });
}

/* 3. Variant logic (value population, image toggles, add/delete) */
function bindVariantBehaviour(){
  // type -> options mapping
  const typeOptions = {
    Color: ["Black","Blue","Red","Green","White"],
    Size: ["XS","S","M","L","XL","XXL"],
    Storage: ["64GB","128GB","256GB","512GB","1TB"],
    Material: ["Cotton","Leather","Polyester","Plastic","Metal","Wood"],
    Packaging: ["Box","Bag","Sachet","Envelope","Bottle","Jar"]
  };

  // Helper to populate value select and toggle color-image-actions
  function updateValueOptions(typeSelect){
    const selected = typeSelect.value;
    const block = typeSelect.closest(".variant-block");
    if (!block) return;
    const valueSelect = block.querySelector(".variant-value");
    if (!valueSelect) return;

    valueSelect.innerHTML = "";
    const options = typeOptions[selected] || [];
    options.forEach(opt => {
      const option = document.createElement("option");
      option.value = opt;
      option.textContent = opt;
      valueSelect.appendChild(option);
    });

    // preload saved value
    const saved = valueSelect.dataset.current || block.dataset.savedValue;
    if (saved) {
      const match = Array.from(valueSelect.options).find(o => o.value === saved);
      if (match) valueSelect.value = saved;
    }

    // show/hide color actions
    const actions = block.querySelector(".color-image-actions");
    if (actions) actions.classList.toggle("d-none", selected !== "Color");
  }

  // run for existing selects on load
  document.querySelectorAll(".variant-type").forEach(s => {
    updateValueOptions(s);
  });

  // delegated change handler
  document.addEventListener("change", e => {
    // variant type select changed
    if (e.target.matches(".variant-type")) {
      updateValueOptions(e.target);
    }

    // file inputs for preview (variant images)
    if (e.target.matches("input[type='file'].variant-image-input")) {
      previewVariantImage({ target: e.target });
    }
  });

  // add / delete buttons (delegated click)
  document.addEventListener("click", e => {
    // Add variant (client-side for new product)
    if (e.target.matches(".add-variant-btn")) {
      e.preventDefault();
      const container = document.getElementById("variant-fields");
      const template = document.getElementById("variant-template");
      if (!container || !template) return;

      const wrapper = document.createElement("div");
      wrapper.innerHTML = template.firstElementChild.outerHTML;
      const clone = wrapper.firstElementChild;

      const key = Date.now().toString();
      // replace placeholders
      clone.innerHTML = clone.innerHTML.replace(/NEW_RECORD/g, key);
      clone.id = `variant_${key}`;
      clone.dataset.key = key;

      container.appendChild(clone);

      // initialize selects inside clone
      clone.querySelectorAll(".variant-type").forEach(s => updateValueOptions(s));
      return;
    }

    // Delete variant (client-side)
    if (e.target.matches(".delete-variant")) {
      e.preventDefault();
      const block = e.target.closest(".variant-block");
      if (!block) return;
      const destroyInput = block.querySelector("input.destroy-flag[name*='[_destroy]']");
      if (destroyInput && destroyInput.name.includes("[id]") === false) {
        // newly created client-side variant: remove DOM
        block.remove();
      } else if (destroyInput) {
        // persisted record: mark _destroy = 1 and hide
        destroyInput.value = "1";
        block.style.display = "none";
      } else {
        block.remove();
      }
      return;
    }

    // Add variant image (client-side for new variants)
    if (e.target.matches(".add-variant-image-btn")) {
      e.preventDefault();

      const block = e.target.closest(".variant-block");
      if (!block) return;

      const imagesWrapper = block.querySelector(".variant-images-wrapper");
      const template = document.getElementById("variant-image-template");

      // If this is edit flow, we expect Turbo to add image (server-side). For new (or client-only) we clone.
      const isEditFlow = block.querySelector("input[name*='[id]']") !== null && block.querySelector("input[name*='[id]']").value !== "";

      // If product is persisted but this variant was persisted too, the controller `add_variant_image` will handle server-side Turbo.
      // For client-only new variants, or when add button is client-side, we clone.
      if (!isEditFlow) {
        if (!imagesWrapper || !template) return;
        const w = document.createElement("div");
        w.innerHTML = template.firstElementChild.outerHTML.trim();
        const newImageBlock = w.firstElementChild;

        // compute indexes: use variant key and image count
        const variantKey = block.dataset.key || Date.now().toString();
        const index = imagesWrapper.querySelectorAll(".variant-image-block").length;

        newImageBlock.querySelectorAll("input, textarea, select").forEach(el => {
          if (el.name) {
            el.name = el.name.replace(/INDEX/g, variantKey).replace(/NEW_IMAGE/g, index);
          }
        });

        imagesWrapper.appendChild(newImageBlock);
      } else {
        // For persisted variant in edit mode: do nothing here — the server endpoint will respond with turbo_stream and append server-side.
      }
      return;
    }

    // Delete variant image (client-side)
    if (e.target.matches(".delete-variant-image")) {
      e.preventDefault();
      const imgBlock = e.target.closest(".variant-image-block");
      if (!imgBlock) return;

      const destroyInput = imgBlock.querySelector("input[name*='[_destroy]']");
      if (destroyInput && destroyInput.type === "hidden") {
        // mark for destroy and hide
        destroyInput.value = "1";
        imgBlock.style.display = "none";
      } else {
        // client-only newly added block
        imgBlock.remove();
      }
      return;
    }
  });
}

/* 4. Variant image preview */
window.previewVariantImage = function(event) {
  const input = event.target;
  const file = input.files && input.files[0];
  if (!file) return;

  let preview = input.closest(".variant-image-block").querySelector(".variant-image-preview");
  if (!preview) {
    preview = document.createElement("img");
    preview.className = "img-thumbnail mb-2 variant-image-preview";
    preview.style.maxHeight = "150px";
    input.insertAdjacentElement("beforebegin", preview);
  }
  preview.src = URL.createObjectURL(file);

  const hiddenUrl = input.closest(".variant-image-block").querySelector(".image-url-field");
  if (hiddenUrl) hiddenUrl.value = preview.src;

  preview.onload = () => URL.revokeObjectURL(preview.src);
};

/* 5. Gallery preview helpers */
function bindGallery(){
  window.previewGalleryImages = function(event) {
    const holder = document.getElementById("gallery-preview");
    if (!holder) return;
    holder.innerHTML = "";
    Array.from(event.target.files || []).forEach(file => {
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
        holder.appendChild(wrapper);
      };
      reader.readAsDataURL(file);
    });
  };

  window.addGalleryInput = function() {
    const galleryInputs = document.getElementById("gallery-inputs");
    if (!galleryInputs) return;
    const input = document.createElement("input");
    input.type = "file";
    input.name = "gallery_images[]";
    input.accept = "image/*";
    input.className = "form-control form-control-sm mb-2";
    input.onchange = window.previewGalleryImages;
    galleryInputs.appendChild(input);
  };
}

/* Utility: addFields used for inventory in your markup */
window.addFields = function(containerId) {
  const container = document.getElementById(containerId);
  const template = document.getElementById(containerId.replace('-fields','-template')) || document.getElementById("inventory-template");
  if (!container || !template) return;
  const wrapper = document.createElement("div");
  wrapper.innerHTML = template.innerHTML.trim();
  container.appendChild(wrapper.firstElementChild);
};


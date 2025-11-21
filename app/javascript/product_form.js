console.log("product_form.js loaded ✅");

// ==================================================================
// 1. GLOBAL FUNCTIONS (Called directly by HTML onclick attributes)
// ==================================================================

/**
 * Generic function to add fields (Used for Inventory)
 */
window.addFields = function(containerId) {
  const container = document.getElementById(containerId);
  const templateId = containerId.replace("-fields", "-template");
  const template = document.getElementById(templateId);

  if (!container || !template) return;

  // ✅ Correct way to clone <template> content
  const clone = template.content.cloneNode(true);
  
  // Convert fragment to HTML string to do replacements
  const tempDiv = document.createElement('div');
  tempDiv.appendChild(clone);
  
  const uniqueId = `new_${Date.now()}`;
  const html = tempDiv.innerHTML.replace(/NEW_RECORD/g, uniqueId);
  
  // Insert into DOM
  container.insertAdjacentHTML('beforeend', html);
};

/**
 * Specific function to add a Variant
 */
window.addVariant = function() {
  const container = document.getElementById("variant-fields");
  const template = document.getElementById("variant-template");

  if (!container || !template) return;

  // ✅ Correct way to clone <template> content
  const clone = template.content.cloneNode(true);
  const tempDiv = document.createElement('div');
  tempDiv.appendChild(clone);

  const uniqueId = `new_${Date.now()}`;
  
  // Replace NEW_RECORD with timestamp
  let html = tempDiv.innerHTML.replace(/NEW_RECORD/g, uniqueId);
  
  // Create the actual DOM element
  const wrapper = document.createElement('div');
  wrapper.innerHTML = html;
  const newBlock = wrapper.firstElementChild;

  // Set the data-key for image nesting logic
  newBlock.setAttribute('data-key', uniqueId);

  container.appendChild(newBlock);

  // Initialize the dropdown for this new block
  const typeSelect = newBlock.querySelector("select[name*='[name]']");
  if (typeSelect) updateValueOptions(typeSelect);
};

// ==================================================================
// 2. EVENT DELEGATION (Handles clicks/changes for dynamic elements)
// ==================================================================

document.addEventListener("turbo:load", () => {
  
  // --- A. Variant Logic (Type/Value Dropdowns) ---
  const typeOptions = {
    Color: ["Black","Blue","Red","Green","White", "Yellow", "Purple"],
    Size: ["XS","S","M","L","XL","XXL"],
    Storage: ["64GB","128GB","256GB","512GB","1TB"],
    Material: ["Cotton","Leather","Polyester","Plastic","Metal","Wood"],
    Packaging: ["Box","Bag","Sachet","Envelope","Bottle","Jar"]
  };

  window.updateValueOptions = function(typeSelect) {
    const selected = typeSelect.value;
    const block = typeSelect.closest(".variant-block");
    const valueSelect = block.querySelector("select.variant-value");
    if (!valueSelect) return;

    // Save current selection if re-populating
    const savedValue = valueSelect.dataset.current || valueSelect.value;

    // Clear and populate
    valueSelect.innerHTML = "<option value=''>Select Option</option>";
    const options = typeOptions[selected] || [];
    
    options.forEach(opt => {
      const option = document.createElement("option");
      option.value = opt;
      option.textContent = opt;
      if (opt === savedValue) option.selected = true;
      valueSelect.appendChild(option);
    });

    // Toggle Color Image Actions
    const actions = block.querySelector(".color-image-actions");
    if (actions) {
      if (selected === "Color") {
        actions.classList.remove("d-none");
      } else {
        actions.classList.add("d-none");
      }
    }
  };

  // Bind change event for Type dropdowns (Delegated)
  document.addEventListener("change", (e) => {
    if (e.target.classList.contains("variant-type")) {
      updateValueOptions(e.target);
    }
  });

  // Initialize existing dropdowns on load
  document.querySelectorAll(".variant-type").forEach(el => updateValueOptions(el));


  // --- B. Add Variant Image (Delegated Click) ---
  document.addEventListener("click", (e) => {
    if (e.target.classList.contains("add-variant-image-btn")) {
      e.preventDefault();
      
      const btn = e.target;
      const variantBlock = btn.closest(".variant-block");
      const imagesWrapper = variantBlock.querySelector(".variant-images-wrapper") || variantBlock.querySelector(".color-image-actions");
      const template = document.getElementById("variant-image-template");

      if (!template) return;

      // 1. Get Parent Variant ID
      // If it's a saved record, the div has an ID like "variant_123". If new, data-key="new_..."
      let variantId = variantBlock.dataset.key; 
      
      // If data-key is missing (persisted record), extract from input name
      if (!variantId) {
        const nameInput = variantBlock.querySelector("select.variant-type");
        const match = nameInput.name.match(/variants_attributes\]\[([^\]]+)\]/);
        variantId = match ? match[1] : null;
      }

      if (!variantId) {
        console.error("Could not find Variant ID");
        return;
      }

      // 2. Clone Template
      const clone = template.content.cloneNode(true);
      const tempDiv = document.createElement('div');
      tempDiv.appendChild(clone);

      // 3. Replace Placeholders
      // INDEX -> Parent Variant ID
      // NEW_IMAGE -> Unique ID for this image
      const uniqueImgId = `new_${Date.now()}`;
      let html = tempDiv.innerHTML
        .replace(/INDEX/g, variantId) // For existing ERB structure
        .replace(/NEW_RECORD/g, variantId) // Fallback if template uses NEW_RECORD
        .replace(/NEW_IMAGE/g, uniqueImgId);

      // 4. Insert before the button
      btn.insertAdjacentHTML('beforebegin', html);
    }
  });


  // --- C. Delete Handling (Variants, Images, Gallery) ---
  document.addEventListener("click", (e) => {
    
    // 1. Delete Gallery Image (Persisted)
    if (e.target.classList.contains("delete-gallery-image")) {
      if (e.target.dataset.url) {
        e.preventDefault(); // Prevent form submit
        const url = e.target.dataset.url;
        const form = e.target.closest("form");
        
        // Add hidden input to remove gallery image in backend
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = "remove_gallery[]";
        input.value = url;
        form.appendChild(input);
        
        e.target.closest(".gallery-image-block").style.display = "none";
      }
    }

    // 2. Delete Variant (Dynamic)
    if (e.target.classList.contains("delete-variant")) {
      e.preventDefault();
      const block = e.target.closest(".variant-block");
      const destroyInput = block.querySelector("input.destroy-flag");
      
      if (destroyInput) {
        destroyInput.value = "true"; // Mark for deletion in Rails
        block.style.display = "none";
      } else {
        block.remove(); // Just remove if it's purely JS-added
      }
    }

    // 3. Delete Variant Image (Dynamic)
    if (e.target.classList.contains("delete-variant-image")) {
      e.preventDefault();
      const block = e.target.closest(".variant-image-block");
      const destroyInput = block.querySelector("input.destroy-flag");

      if (destroyInput) {
        destroyInput.value = "true";
        block.style.display = "none";
      } else {
        block.remove();
      }
    }
  });


  // --- D. Image Previews (Generic) ---
  window.previewMainImage = function(event) {
    const output = document.getElementById("main-image-preview");
    if (event.target.files[0]) {
      output.src = URL.createObjectURL(event.target.files[0]);
      output.style.display = "block";
    }
  };

  window.previewGalleryImages = function(event) {
    const previewDiv = document.getElementById("gallery-preview");
    previewDiv.innerHTML = "";
    Array.from(event.target.files).forEach(file => {
      const img = document.createElement("img");
      img.src = URL.createObjectURL(file);
      img.classList.add("img-thumbnail", "m-1");
      img.style.height = "100px";
      previewDiv.appendChild(img);
    });
  };

  // Delegated change event for any variant image input
  document.addEventListener("change", (e) => {
    if (e.target.type === "file" && e.target.closest(".variant-image-block")) {
      const file = e.target.files[0];
      if (file) {
        let img = e.target.previousElementSibling; // Assuming img tag is before input
        if (!img || !img.tagName === 'IMG') {
           // If not found (e.g. new record), create it
           img = document.createElement("img");
           img.classList.add("img-thumbnail", "mb-2", "variant-image-preview");
           img.style.maxHeight = "150px";
           e.target.parentNode.insertBefore(img, e.target);
        }
        img.src = URL.createObjectURL(file);
      }
    }
  });


  // --- E. Price Calculation ---
  const priceField = document.getElementById("product_price");
  const shippingField = document.getElementById("product_shipping_cost");
  const totalSpan = document.getElementById("total-cost");

  function calcTotal() {
    const p = parseFloat(priceField.value) || 0;
    const s = parseFloat(shippingField.value) || 0;
    if(totalSpan) totalSpan.textContent = `KES ${(p + s).toFixed(2)}`;
  }

  if (priceField && shippingField) {
    priceField.addEventListener("input", calcTotal);
    shippingField.addEventListener("input", calcTotal);
  }

});

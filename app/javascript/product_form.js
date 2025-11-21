// product_form.js
console.log("product_form.js loaded");

/*
  FIXES INCLUDED:
  - No more insertBefore errors
  - No storing of blob: URLs
  - Image previews work correctly with Supabase uploads
  - Clean variant/image cloning for NEW and EDIT forms
*/

document.addEventListener("turbo:load", initProductForm);
document.addEventListener("DOMContentLoaded", initProductForm);

function initProductForm() {
  bindPriceShipping();
  bindCategoryAjax();
  bindVariantBehaviour();
  bindGallery();
}

/* -----------------------------
   1. Price + Shipping
--------------------------------*/
function bindPriceShipping() {
  const priceField = document.getElementById("product_price");
  const shippingField = document.getElementById("product_shipping_cost");
  const totalCostSpan = document.getElementById("total-cost");

  const update = () => {
    const p = parseFloat(priceField?.value) || 0;
    const s = parseFloat(shippingField?.value) || 0;
    if (totalCostSpan) totalCostSpan.textContent = `KES ${(p + s).toFixed(2)}`;
  };

  priceField?.addEventListener("input", update);
  shippingField?.addEventListener("input", update);
}

/* -----------------------------
   2. Category → Subcategory AJAX
--------------------------------*/
function bindCategoryAjax() {
  const cat = document.getElementById("category-select");
  const sub = document.getElementById("subcategory-select");
  if (!cat || !sub) return;

  cat.addEventListener("change", e => {
    fetch(`/categories/${e.target.value}/subcategories.json`)
      .then(res => res.json())
      .then(list => {
        sub.innerHTML = "<option value=''>Select a subcategory</option>";
        list.forEach(item => {
          const opt = document.createElement("option");
          opt.value = item.id;
          opt.textContent = item.name;
          sub.appendChild(opt);
        });
      })
      .catch(err => console.error("Subcategory fetch failed:", err));
  });
}

/* -----------------------------
   3. Variant Logic
--------------------------------*/
function bindVariantBehaviour() {
  const typeOptions = {
    Color: ["Black", "Blue", "Red", "Green", "White"],
    Size: ["XS", "S", "M", "L", "XL", "XXL"],
    Storage: ["64GB", "128GB", "256GB", "512GB", "1TB"],
    Material: ["Cotton", "Leather", "Polyester", "Plastic", "Metal", "Wood"],
    Packaging: ["Box", "Bag", "Sachet", "Envelope", "Bottle", "Jar"]
  };

  function updateValueOptions(typeSelect) {
    const block = typeSelect.closest(".variant-block");
    const valueSelect = block.querySelector(".variant-value");
    const selected = typeSelect.value;

    valueSelect.innerHTML = "";
    (typeOptions[selected] || []).forEach(v => {
      const opt = document.createElement("option");
      opt.value = opt.textContent = v;
      valueSelect.appendChild(opt);
    });

    const saved = valueSelect.dataset.current || block.dataset.savedValue;
    if (saved && [...valueSelect.options].some(o => o.value === saved)) {
      valueSelect.value = saved;
    }

    const actions = block.querySelector(".color-image-actions");
    if (actions) actions.classList.toggle("d-none", selected !== "Color");
  }

  document.querySelectorAll(".variant-type").forEach(updateValueOptions);

  document.addEventListener("change", e => {
    if (e.target.matches(".variant-type")) {
      updateValueOptions(e.target);
    }

    if (e.target.matches("input[type='file'].variant-image-input")) {
      previewVariantImage(e);
    }
  });

  document.addEventListener("click", e => {

    /* ADD VARIANT */
    if (e.target.matches(".add-variant-btn")) {
      e.preventDefault();
      const container = document.getElementById("variant-fields");
      const template = document.getElementById("variant-template");
      if (!container || !template) return;

      const wrapper = document.createElement("div");
      wrapper.innerHTML = template.firstElementChild.outerHTML.trim();
      const clone = wrapper.firstElementChild;

      const key = Date.now().toString();
      clone.innerHTML = clone.innerHTML.replace(/NEW_RECORD/g, key);
      clone.dataset.key = key;

      container.appendChild(clone);

      clone.querySelectorAll(".variant-type").forEach(updateValueOptions);
      return;
    }

    /* DELETE VARIANT */
    if (e.target.matches(".delete-variant")) {
      e.preventDefault();
      const block = e.target.closest(".variant-block");
      const destroy = block.querySelector("input[name*='[_destroy]']");

      if (destroy && destroy.name.includes("[id]")) {
        destroy.value = "1";
        block.style.display = "none";
      } else {
        block.remove();
      }
      return;
    }

    /* ADD VARIANT IMAGE */
    if (e.target.matches(".add-variant-image-btn")) {
      e.preventDefault();
      const block = e.target.closest(".variant-block");
      const wrapper = block.querySelector(".variant-images-wrapper");
      const template = document.getElementById("variant-image-template");
      if (!block || !wrapper || !template) return;

      const variantKey = block.dataset.key;
      const index = wrapper.querySelectorAll(".variant-image-block").length;

      const newEl = template.firstElementChild.cloneNode(true);

      newEl.querySelectorAll("[name]").forEach(el => {
        el.name = el.name
          .replace(/INDEX/g, variantKey)
          .replace(/NEW_IMAGE/g, index);
      });

      wrapper.appendChild(newEl);
      return;
    }

    /* DELETE VARIANT IMAGE */
    if (e.target.matches(".delete-variant-image")) {
      e.preventDefault();
      const imgBlock = e.target.closest(".variant-image-block");
      const destroy = imgBlock.querySelector("input[name*='[_destroy]']");

      if (destroy) {
        destroy.value = "1";
        imgBlock.style.display = "none";
      } else {
        imgBlock.remove();
      }
      return;
    }
  });
}

/* -----------------------------
   4. Preview Variant Image
--------------------------------*/
window.previewVariantImage = function (event) {
  const input = event.target;
  const file = input.files?.[0];
  if (!file) return;

  const block = input.closest(".variant-image-block");
  let preview = block.querySelector(".variant-image-preview");

  if (!preview) {
    preview = document.createElement("img");
    preview.className = "img-thumbnail mb-2 variant-image-preview";
    preview.style.maxHeight = "150px";
    input.insertAdjacentElement("beforebegin", preview);
  }

  const tempUrl = URL.createObjectURL(file);
  preview.src = tempUrl;

  // DO NOT store blob: or temp URLs in image_url
  const hiddenUrl = block.querySelector(".image-url-field");
  if (hiddenUrl) hiddenUrl.value = "";

  preview.onload = () => URL.revokeObjectURL(tempUrl);
};

/* -----------------------------
   5. Gallery Image Preview
--------------------------------*/
function bindGallery() {
  window.previewGalleryImages = function (event) {
    const holder = document.getElementById("gallery-preview");
    holder.innerHTML = "";

    [...event.target.files].forEach(file => {
      const reader = new FileReader();
      reader.onload = e => {
        const box = document.createElement("div");
        box.className = "col-md-3 mb-2 text-center preview-item";

        const img = document.createElement("img");
        img.src = e.target.result;
        img.className = "img-thumbnail";
        img.style.maxHeight = "150px";

        const btn = document.createElement("button");
        btn.className = "btn btn-sm btn-outline-danger mt-2";
        btn.textContent = "Remove";
        btn.onclick = () => box.remove();

        box.appendChild(img);
        box.appendChild(btn);
        holder.appendChild(box);
      };
      reader.readAsDataURL(file);
    });
  };
}

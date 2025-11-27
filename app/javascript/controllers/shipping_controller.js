import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="shipping"
export default class extends Controller {
  static targets = ["city", "country", "county"]

  updatePreview() {
    const city    = this.cityTarget.value
    const country = this.countryTarget.value
    const county  = this.countyTarget.value

    const url = `/orders/shipping_preview?city=${encodeURIComponent(city)}&country=${encodeURIComponent(country)}&county=${encodeURIComponent(county)}`
    Turbo.visit(url, { frame: "shipping_preview" })
  }
}

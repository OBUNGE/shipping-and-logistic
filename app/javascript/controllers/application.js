import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Optional: turn off debug logging in production
application.debug = false
window.Stimulus = application

export { application }

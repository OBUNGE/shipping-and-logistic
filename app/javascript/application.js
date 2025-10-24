import "@hotwired/turbo-rails"
import "controllers"
import "./star_rating"

Turbo.config.drive.progressBarDelay = 0
Turbo.config.debug = true
 

import "@rails/ujs"
import "@rails/activestorage"
import "channels"

//= require jquery
//= require bootstrap-sprockets

import "bootstrap/dist/js/bootstrap.bundle"

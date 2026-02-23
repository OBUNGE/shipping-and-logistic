require "selenium/webdriver"
require "securerandom"

CHROME_FOR_TESTING_PATH = "/usr/local/chrome-for-testing/145.0.7632.77"
ENV['CHROME_BIN'] ||= File.join(CHROME_FOR_TESTING_PATH, "chrome")
ENV['CHROMEDRIVER_PATH'] ||= File.join(CHROME_FOR_TESTING_PATH, "chromedriver")

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--disable-gpu")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1400,1400")
  options.add_argument("--user-data-dir=/tmp/chrome-profile-#{SecureRandom.hex(8)}")

  # Force Selenium to use Chrome-for-Testing binary
  chrome_bin = ENV['CHROME_BIN']
  if chrome_bin && File.exist?(chrome_bin) && File.executable?(chrome_bin)
    options.binary = chrome_bin
    warn "Capybara/Selenium: using Chrome binary at #{chrome_bin}"
  else
    warn "Capybara/Selenium: Chrome binary not found at #{chrome_bin}"
  end

  # Force Selenium to use the matching chromedriver
  chromedriver_path = ENV['CHROMEDRIVER_PATH']
  service = if chromedriver_path && File.exist?(chromedriver_path)
              Selenium::WebDriver::Service.chrome(path: chromedriver_path)
            else
              raise "Chromedriver not found at #{chromedriver_path}. Please download it from Chrome-for-Testing releases."
            end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service)
end

Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 20

# Ensure the server is reachable by the browser driver when using Selenium.
# Use Puma (fast, thread-safe) and bind to loopback so the browser can connect.
Capybara.server = :puma, { Silent: true }
Capybara.server_host = '127.0.0.1'
# Pick an explicit port to avoid ephemeral binding issues in some CI environments.
Capybara.server_port = 9887
Capybara.app_host = "http://#{Capybara.server_host}:#{Capybara.server_port}"

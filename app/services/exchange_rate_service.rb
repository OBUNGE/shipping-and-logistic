# app/services/exchange_rate_service.rb
require "net/http"
require "json"

class ExchangeRateService
  BASE_URL = "https://v6.exchangerate-api.com/v6"
  API_KEY  = ENV["EXCHANGE_RATE_API_KEY"]

  # Fallback rates (KES as anchor)
  FALLBACK_RATES = {
    "USD_KES" => 130.0,       # 1 USD = 130 KES
    "KES_USD" => 1.0 / 130.0  # 1 KES = 0.0077 USD
  }.freeze

  class << self
    def convert(amount, from:, to:)
      return amount if from == to

      rate = get(from, to) || FALLBACK_RATES["#{from}_#{to}"]
      raise ArgumentError, "Unsupported conversion #{from} → #{to}" unless rate

      (amount.to_f * rate).round(2)
    end

    private

    def get(from_currency, to_currency)
      url = URI("#{BASE_URL}/#{API_KEY}/latest/#{from_currency}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.open_timeout = 3
      http.read_timeout = 5

      response = http.get(url.request_uri)
      data = JSON.parse(response.body) rescue {}

      if data["result"] == "success"
        data.dig("conversion_rates", to_currency)
      else
        Rails.logger.error("ExchangeRateService error: #{data.inspect}")
        nil
      end
    rescue => e
      Rails.logger.error("ExchangeRateService exception: #{e.message}")
      nil
    end
  end
end

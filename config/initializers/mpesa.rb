require 'httparty'

module Mpesa
  DARAJA_BASE_URL = "https://sandbox.safaricom.co.ke"

  CONSUMER_KEY = ENV['MPESA_CONSUMER_KEY']
  CONSUMER_SECRET = ENV['MPESA_CONSUMER_SECRET']
  SHORTCODE = ENV['MPESA_SHORTCODE'] # e.g. 174379 for Lipa na Mpesa Online
  PASSKEY = ENV['MPESA_PASSKEY'] # From Safaricom Portal

  def self.generate_token
    url = "#{DARAJA_BASE_URL}/oauth/v1/generate?grant_type=client_credentials"
    auth = { username: CONSUMER_KEY, password: CONSUMER_SECRET }
    response = HTTParty.get(url, basic_auth: auth)
    response['access_token']
  end
end

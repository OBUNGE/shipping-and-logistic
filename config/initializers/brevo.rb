# 📄 config/initializers/brevo.rb
require "sib-api-v3-sdk"

class BrevoMailerDelivery
  def initialize(options = {})
    # Configure Brevo SDK with API key
    SibApiV3Sdk.configure do |config|
      config.api_key["api-key"] = ENV["BREVO_API_KEY"]
    end

    @client = SibApiV3Sdk::TransactionalEmailsApi.new
  end

  def deliver!(mail)
    api_instance = @client

    # Ensure we have a sender email (fallback to admin@tajaone.app)
    sender_email = mail.from&.first || ENV.fetch("BREVO_SENDER_EMAIL", "admin@tajaone.app")

    # Plain‑text fallback if none provided
    text_content = ActionView::Base.full_sanitizer.sanitize(mail.body.encoded).squish

    # Build Brevo email object
    send_smtp_email = SibApiV3Sdk::SendSmtpEmail.new(
      to: mail.to.map { |email| { email: email } },
      sender: { email: sender_email, name: "tajaone" },
      subject: mail.subject,
      htmlContent: mail.body.encoded,
      textContent: text_content
    )

    Rails.logger.info("📧 Brevo payload: #{send_smtp_email.to_hash}")

    begin
      response = api_instance.send_transac_email(send_smtp_email)
      Rails.logger.info("✅ Brevo email sent successfully to #{mail.to.join(", ")} | Response: #{response.inspect}")
      response
    rescue SibApiV3Sdk::ApiError => e
      Rails.logger.error("❌ Brevo API error: #{e.code} | #{e.response_body}")
      raise e
    rescue => e
      Rails.logger.error("❌ Brevo send failed: #{e.message}")
      raise e
    end
  end
end

# Register Brevo as a delivery method
ActionMailer::Base.add_delivery_method :brevo_api, BrevoMailerDelivery

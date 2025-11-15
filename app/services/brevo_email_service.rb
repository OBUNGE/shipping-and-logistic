# 📄 app/services/brevo_email_service.rb
require 'sib-api-v3-sdk'

class BrevoEmailService
  def initialize
    SibApiV3Sdk.configure do |config|
      # Load the Brevo API key from environment
      config.api_key['api-key'] = ENV['BREVO_API_KEY']
    end
    @api_instance = SibApiV3Sdk::TransactionalEmailsApi.new
  end

  def send_email(to_email:, to_name:, subject:, html_content:, text_content: nil)
    # Validate inputs before sending
    if to_email.blank? || subject.blank? || html_content.blank?
      Rails.logger.error("❌ Brevo send failed: Missing required fields (to_email, subject, html_content)")
      return { error: "Missing required fields" }
    end

    # Use a verified sender email (default to admin@tajaone.app if none set)
    sender_email = ENV.fetch("BREVO_SENDER_EMAIL", "admin@tajaone.app")

    # Auto-generate plain-text fallback if not provided
    text_content ||= ActionView::Base.full_sanitizer.sanitize(html_content).squish

    # Log payload before sending
    Rails.logger.info(
      "📧 Brevo payload: to=#{to_email}, sender=#{sender_email}, subject=#{subject}, html_present=#{html_content.present?}, text_present=#{text_content.present?}"
    )

    # Build the email object
    email = SibApiV3Sdk::SendSmtpEmail.new(
      to: [{ email: to_email, name: to_name }],
      sender: { email: sender_email, name: "tajaone" },
      subject: subject,
      htmlContent: html_content,
      textContent: text_content
    )

    Rails.logger.info("📧 Raw email object: #{email.to_hash}")

    begin
      # Send the email via Brevo API
      response = @api_instance.send_transac_email(email)
      Rails.logger.info("✅ Brevo email sent successfully to #{to_email} | Response: #{response.inspect}")
      response
    rescue SibApiV3Sdk::ApiError => e
      Rails.logger.error("❌ Brevo API error: #{e.code} | #{e.response_body}")
      { error: e.message, details: e.response_body }
    rescue => e
      Rails.logger.error("❌ Brevo send failed: #{e.message}")
      { error: e.message }
    end
  end
end

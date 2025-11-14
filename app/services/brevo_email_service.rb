# app/services/brevo_email_service.rb
require 'sib-api-v3-sdk'

class BrevoEmailService
  def initialize
    SibApiV3Sdk.configure do |config|
      config.api_key['api-key'] = ENV['BREVO_API_KEY']
    end
    @api_instance = SibApiV3Sdk::TransactionalEmailsApi.new
  end

  def send_email(to_email:, to_name:, subject:, html_content:)
    # Validate inputs before sending
    if to_email.blank? || subject.blank? || html_content.blank?
      Rails.logger.error("❌ Brevo send failed: Missing required fields (to_email, subject, html_content)")
      return { error: "Missing required fields" }
    end

    # Use a verified sender email
    sender_email = ENV.fetch("BREVO_SENDER_EMAIL", "admin@tajaone.app")

    email = SibApiV3Sdk::SendSmtpEmail.new(
      to: [{ email: to_email, name: to_name }],
      sender: { email: sender_email, name: "tajaone" },
      subject: subject,
      html_content: html_content
    )

    begin
      response = @api_instance.send_transac_email(email)
      Rails.logger.info("📧 Brevo email sent successfully to #{to_email} | Response: #{response.inspect}")
      response
    rescue SibApiV3Sdk::ApiError => e
      Rails.logger.error("❌ Brevo API error: #{e.message}")
      { error: e.message }
    rescue => e
      Rails.logger.error("❌ Brevo send failed: #{e.message}")
      { error: e.message }
    end
  end
end

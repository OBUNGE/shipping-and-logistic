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
    email = SibApiV3Sdk::SendSmtpEmail.new(
      to: [{ email: to_email, name: to_name }],
      sender: { email: "no-reply@tajaone.app", name: "tajaone" },
      subject: subject,
      html_content: html_content
    )
    @api_instance.send_transac_email(email)
  end
end

class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@yourdomain.com'  # later replace with your custom domain email
  layout 'mailer'
end

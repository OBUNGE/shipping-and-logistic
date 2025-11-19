# app/services/supabase_service.rb
require "faraday"
require "securerandom"
require "uri"

class SupabaseService
  def self.upload(file, path_prefix: "variant_images")
    return nil unless file

    # Encode filename to be URI-safe
    safe_name = URI.encode_www_form_component(file.original_filename)
    filename  = "#{path_prefix}/#{SecureRandom.uuid}-#{safe_name}"
    bucket    = "product-images"

    conn = Faraday.new(
      url: ENV["SUPABASE_URL"],
      headers: {
        "apikey"        => ENV["SUPABASE_SECRET_ACCESS_KEY"],
        "Authorization" => "Bearer #{ENV["SUPABASE_SECRET_ACCESS_KEY"]}",
        "Content-Type"  => "application/octet-stream"
      }
    )

    upload_url = "#{ENV["SUPABASE_URL"]}/storage/v1/object/#{bucket}/#{filename}"

    resp = conn.post(upload_url, file.tempfile.read)

    unless resp.success?
      Rails.logger.error("Supabase upload failed: #{resp.status} - #{resp.body}")
      return nil
    end

    # Public URL (same encoding)
    "#{ENV["SUPABASE_URL"]}/storage/v1/object/public/#{bucket}/#{filename}"
  end
end

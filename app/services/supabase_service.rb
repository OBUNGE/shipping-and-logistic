# app/services/supabase_service.rb
require "faraday"
require "securerandom"

class SupabaseService
  def self.upload(file, path_prefix: "variant_images")
    return nil unless file

    # Sanitize filename to avoid spaces/special chars
    safe_name = file.original_filename.parameterize(separator: "_")
    filename  = "#{path_prefix}/#{SecureRandom.uuid}-#{safe_name}"
    bucket    = "product-images"

    # Build full upload URL
    upload_url = "#{ENV["SUPABASE_URL"]}/storage/v1/object/#{bucket}/#{filename}"

    conn = Faraday.new(
      headers: {
        "apikey"        => ENV["SUPABASE_SECRET_ACCESS_KEY"],
        "Authorization" => "Bearer #{ENV["SUPABASE_SECRET_ACCESS_KEY"]}",
        "Content-Type"  => "application/octet-stream"
      }
    )

    resp = conn.post(upload_url, file.tempfile.read)

    unless resp.success?
      Rails.logger.error("❌ Supabase upload failed: #{resp.status} - #{resp.body}")
      return nil
    end

    # Return public URL
    public_url = "#{ENV["SUPABASE_URL"]}/storage/v1/object/public/#{bucket}/#{filename}"
    Rails.logger.info("✅ Supabase upload successful: #{public_url}")
    public_url
  end
end

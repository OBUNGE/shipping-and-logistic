# app/services/supabase_service.rb
require "net/http"
require "securerandom"
require "uri"

class SupabaseService
  def self.upload(file, path_prefix: "variant_images")
    return nil unless file.respond_to?(:original_filename) && file.respond_to?(:read)

    # Sanitize filename
    safe_name = file.original_filename.parameterize(separator: "_")
    filename  = "#{path_prefix}/#{SecureRandom.uuid}-#{safe_name}"
    bucket    = ENV["SUPABASE_BUCKET"]
    project_ref = ENV["SUPABASE_ACCESS_KEY_ID"]

    # Upload URL (PUT, no /public here)
    endpoint = "https://#{project_ref}.supabase.co/storage/v1/object/#{bucket}/#{filename}"
    uri = URI(endpoint)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Put.new(uri)
    request["Authorization"] = "Bearer #{ENV['SUPABASE_SECRET_ACCESS_KEY']}"
    request["apikey"]        = ENV["SUPABASE_SECRET_ACCESS_KEY"]
    request["Content-Type"]  = file.content_type || "application/octet-stream"

    # Rewind before reading to avoid empty uploads
    file.tempfile.rewind
    request.body = file.read

    response = http.request(request)

    if response.code.to_i == 200
      public_url = "https://#{project_ref}.supabase.co/storage/v1/object/public/#{bucket}/#{filename}"
      Rails.logger.info("✅ Supabase upload successful: #{public_url}")
      public_url
    else
      Rails.logger.error("❌ Supabase upload failed: #{response.code} - #{response.body}")
      nil
    end
  end
end

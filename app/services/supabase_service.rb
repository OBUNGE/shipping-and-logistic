# app/services/supabase_service.rb
require "faraday"
require "securerandom"

class SupabaseService
  def self.upload(file, path_prefix: "variant_images")
    return nil unless file

    filename = "#{path_prefix}/#{SecureRandom.uuid}-#{file.original_filename}"
    bucket   = "product-images"

    conn = Faraday.new(
      url: ENV["SUPABASE_URL"],
      headers: {
        "apikey"       => ENV["SUPABASE_SECRET_ACCESS_KEY"],
        "Authorization"=> "Bearer #{ENV["SUPABASE_SECRET_ACCESS_KEY"]}",
        "Content-Type" => "application/octet-stream"
      }
    )

    # Upload file to Supabase Storage
    resp = conn.post("/storage/v1/object/#{bucket}/#{filename}", file.tempfile.read)

    unless resp.success?
      Rails.logger.error("Supabase upload failed: #{resp.status} - #{resp.body}")
      return nil
    end

    # Return public URL
    "#{ENV["SUPABASE_URL"]}/storage/v1/object/public/#{bucket}/#{filename}"
  end
end

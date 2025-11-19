# app/services/supabase_service.rb
require "supabase"

class SupabaseService
  def self.client
    @client ||= Supabase::Client.new(
      ENV["SUPABASE_URL"],
      ENV["SUPABASE_SECRET_ACCESS_KEY"]
    )
  end

  def self.upload(file, path_prefix: "variant_images")
    return nil unless file

    filename = "#{path_prefix}/#{SecureRandom.uuid}-#{file.original_filename}"
    bucket = "product-images"

    # Upload to Supabase Storage
    client.storage.from(bucket).upload(filename, file.tempfile)

    # Get public URL
    client.storage.from(bucket).get_public_url(filename)
  end
end

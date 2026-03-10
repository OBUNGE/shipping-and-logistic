# lib/tiktok_events.rb
require 'net/http'
require 'uri'
require 'json'

module TikTokEvents
  PIXEL_CODE = "D6NUQKBC77UET383R3KG"
  ACCESS_TOKEN = "0c1037c68912989cf52fd469b5cd8eb5f3f3c0ac"
  API_ENDPOINT = "https://business-api.tiktokglobalshop.com/open_api/v1.3/event/track/"

  def self.track_event(event_name, event_id:, event_time:, properties:, context:)
    uri = URI(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    payload = {
      pixel_code: PIXEL_CODE,
      event: event_name,
      event_id: event_id,
      event_time: event_time.to_i,
      properties: properties,
      context: context
    }

    request = Net::HTTP::Post.new(uri.path, {
      "Content-Type" => "application/json",
      "Access-Token" => ACCESS_TOKEN
    })
    request.body = payload.to_json

    response = http.request(request)
    Rails.logger.info("TikTok Event #{event_name} sent: #{response.body}")
    response
  end

  # ViewContent
  def self.track_view_content(product, user)
    track_event(
      "ViewContent",
      event_id: "view_#{product.id}_#{user.id}",
      event_time: Time.now.to_i,
      properties: {
        value: product.price,
        currency: "KES",
        content_id: product.id.to_s,
        content_type: "product",
        content_name: product.name,
        url: "https://tajaone.app/products/#{product.id}"
      },
      context: {
        email: user.email,
        ip: user.current_sign_in_ip,
        user_agent: user.last_user_agent
      }
    )
  end

  # AddToCart
  def self.track_add_to_cart(cart_item, user)
    track_event(
      "AddToCart",
      event_id: "cart_#{cart_item.id}_#{user.id}",
      event_time: Time.now.to_i,
      properties: {
        value: cart_item.price,
        currency: "KES",
        content_id: cart_item.product.id.to_s,
        content_type: "product",
        content_name: cart_item.product.name,
        url: "https://tajaone.app/cart"
      },
      context: {
        email: user.email,
        ip: user.current_sign_in_ip,
        user_agent: user.last_user_agent
      }
    )
  end

  # InitiateCheckout
  def self.track_checkout(order, user)
    track_event(
      "InitiateCheckout",
      event_id: "checkout_#{order.id}_#{user.id}",
      event_time: Time.now.to_i,
      properties: {
        value: order.total_price,
        currency: "KES",
        content_id: order.id.to_s,
        content_type: "order",
        content_name: "Checkout for Order #{order.id}",
        url: "https://tajaone.app/checkout/#{order.id}"
      },
      context: {
        email: user.email,
        ip: user.current_sign_in_ip,
        user_agent: user.last_user_agent
      }
    )
  end

  # Purchase
  def self.track_purchase(order, user)
    track_event(
      "Purchase",
      event_id: "order_#{order.id}_#{user.id}",
      event_time: Time.now.to_i,
      properties: {
        value: order.total_price,
        currency: "KES",
        content_id: order.id.to_s,
        content_type: "order",
        content_name: "Order #{order.id}",
        url: "https://tajaone.app/orders/#{order.id}"
      },
      context: {
        email: user.email,
        ip: user.current_sign_in_ip,
        user_agent: user.last_user_agent
      }
    )
  end
end

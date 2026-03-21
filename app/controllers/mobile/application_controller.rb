module Mobile
  class ApplicationController < ::ApplicationController
    layout 'mobile'

    protected

    def set_layout
      'mobile'
    end
  end
end

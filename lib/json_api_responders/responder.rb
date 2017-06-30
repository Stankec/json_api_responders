require 'json_api_responders/responder/actions'
require 'json_api_responders/responder/sanitizers'

module JsonApiResponders
  class Responder
    include Actions

    attr_accessor :errors
    attr_accessor :status
    attr_reader :resource
    attr_reader :options
    attr_reader :params
    attr_reader :controller
    attr_reader :namespace

    def initialize(resource, options = {})
      @resource = resource
      @options = options
      self.status = @options[:status]
      @params = @options[:params]
      @controller = @options[:controller]
      @namespace = @options[:namespace]
    end

    def respond!
      render_response
    end

    def not_found
      self.errors = {
        reason: I18n.t('json_api.errors.not_found.reason')
      }
      render_error
    end

    def unauthorized
      self.errors = {
        reason: I18n.t('json_api.errors.unauthorized.reason')
      }
      render_error
    end

    private

    def status=(status)
      @status = Sanitizers.status(status)
    end

    def status_code
      Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
    end

    def action
      params[:action]
    end

    def render_response
      return send("respond_to_#{action}_action") if action.in?(ACTIONS)
      raise(JsonApi::Errors::UnknownAction, action)
    end

    def render_error
      controller.render(error_render_options)
    end

    def error_render_options
      render_options.merge(
        json: {
          status: status_code,
          message: general_error_message
        }.tap do |added_errors|
          added_errors[:errors] = error_response unless errors
          added_errors[:resource] = resource.model if errors
          added_errors[:message] = errors[:reason] if errors
        end
      )
    end

    def render_options
      {
        status: status,
        content_type: 'application/vnd.api+json'
      }
    end

    def error_response
      return if errors
      resource.errors.inject([]) do |new_errors, (attribute, message)|
        new_errors << {
          resource: resource_name.titleize,
          field: attribute,
          reason: message,
          detail: resource.errors.full_message(attribute, message)
        }
      end
    end

    def resource_name
      return resource.object.class.name if resource.respond_to?(:decorated?)
      resource.class.name
    end

    def general_error_message
      I18n.t('json_api.errors.conflict.reason')
    end
  end
end

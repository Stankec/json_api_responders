module JsonApiResponders
  class Responder
    module Actions
      ACTIONS = %w(index show create update destroy).freeze

      def respond_to_index_action
        self.status ||= :ok
        render_resource
      end

      def respond_to_show_action
        self.status ||= :ok
        render_resource
      end

      def respond_to_create_action
        if resource.persisted? && resource.valid?
          self.status ||= :created
          render_resource
        else
          self.status ||= :conflict
          render_error
        end
      end

      def respond_to_update_action
        if resource.valid?
          self.status ||= :ok
          render_resource
        else
          self.status ||= :conflict
          render_error
        end
      end

      def respond_to_destroy_action
        self.status ||= :no_content
        controller.head(status, render_options)
      end

      def render_resource
        controller.render(resource_render_options)
      end

      def resource_render_options
        serializer_key = relation? ? :each_serializer : :serializer

        render_options.merge(
          json: resource
        ).tap do |extra_options|
          extra_options[serializer_key] = serializer_class if
            responder_type_eql?(:serializer)
        end
      end

      def serializer_class
        options[:serializer] ||=
          [
            namespace,
            "#{resource_class}Serializer"
          ].compact.join('::').constantize
      end

      def resource_class
        return resource.model if relation?
        resource.class
      end

      def relation?
        resource.is_a?(ActiveRecord::Relation)
      end

      def responder_type_eql?(type)
        JsonApiResponders.configuration.default_responder_type.eql?(type)
      end
    end
  end
end

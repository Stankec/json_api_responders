module JsonApiResponders
  class Engine < ::Rails::Engine
    isolate_namespace JsonApiResponders
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  end
end

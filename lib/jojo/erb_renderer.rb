# lib/jojo/erb_renderer.rb
require "erb"

module Jojo
  class ErbRenderer
    def initialize(template_path)
      @template_path = template_path
    end

    def render(data)
      template_content = File.read(@template_path)
      erb = ERB.new(template_content, trim_mode: "-")

      # Create a binding with data as local variables
      binding_obj = create_binding(data)
      erb.result(binding_obj)
    end

    private

    def create_binding(data)
      # Store data for later access
      @data = data

      # Create a clean binding with data fields as local variables
      data.each do |key, value|
        instance_variable_set("@#{key}", value)
      end

      # Define methods to access instance variables in ERB
      data.keys.each do |key|
        define_singleton_method(key) do
          instance_variable_get("@#{key}")
        end
      end

      binding
    end

    def method_missing(method_name, *args, &block)
      @data&.dig(method_name.to_s)
    end

    def respond_to_missing?(method_name, include_private = false)
      @data&.key?(method_name.to_s) || super
    end
  end
end

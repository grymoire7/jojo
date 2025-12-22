module Jojo
  class Employer
    attr_reader :name, :slug, :base_path

    def initialize(name)
      @name = name
      @slug = slugify(name)
      @base_path = File.join('employers', @slug)
    end

    private

    def slugify(text)
      text
        .downcase
        .gsub(/[^a-z0-9]+/, '-')
        .gsub(/^-|-$/, '')
    end
  end
end

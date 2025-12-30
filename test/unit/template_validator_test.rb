require_relative '../test_helper'
require_relative '../../lib/jojo/template_validator'

describe Jojo::TemplateValidator do
  describe '.appears_unchanged?' do
    it 'returns false when file does not exist' do
      result = Jojo::TemplateValidator.appears_unchanged?('nonexistent.md')
      _(result).must_equal false
    end

    it 'returns true when file contains marker' do
      file = Tempfile.new(['test', '.md'])
      file.write("<!-- JOJO_TEMPLATE_PLACEHOLDER - Delete this line -->\nContent")
      file.close

      result = Jojo::TemplateValidator.appears_unchanged?(file.path)
      _(result).must_equal true

      file.unlink
    end

    it 'returns false when file does not contain marker' do
      file = Tempfile.new(['test', '.md'])
      file.write("# My Resume\nCustomized content")
      file.close

      result = Jojo::TemplateValidator.appears_unchanged?(file.path)
      _(result).must_equal false

      file.unlink
    end
  end
end

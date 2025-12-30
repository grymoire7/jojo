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

  describe '.validate_required_file!' do
    it 'raises error when required file is missing' do
      err = assert_raises(Jojo::TemplateValidator::MissingInputError) do
        Jojo::TemplateValidator.validate_required_file!('inputs/nonexistent.md', 'generic resume')
      end
      _(err.message).must_include 'inputs/nonexistent.md not found'
      _(err.message).must_include 'jojo setup'
    end

    it 'does not raise when file exists without marker' do
      file = Tempfile.new(['test', '.md'])
      file.write("# Customized Resume")
      file.close

      Jojo::TemplateValidator.validate_required_file!(file.path, 'resume')

      file.unlink
    end
  end
end

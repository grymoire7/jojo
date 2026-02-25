# test/unit/commands/pdf/converter_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/pdf/converter"
require_relative "../../../../lib/jojo/application"

class Jojo::Commands::Pdf::ConverterTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("test-employer")
    @application.instance_variable_set(:@base_path, @tmpdir)
  end

  # -- generate_resume_pdf --

  def test_generate_resume_pdf_creates_html_and_pdf_files
    File.write(@application.resume_path, "# My Resume\n\nContent here")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    call_count = 0
    generator.stub(:system, lambda { |_cmd|
      call_count += 1
      FileUtils.touch(@application.resume_html_path) if call_count == 1
      FileUtils.touch(@application.resume_pdf_path) if call_count == 2
      true
    }) do
      generator.generate_resume_pdf
      assert File.exist?(@application.resume_html_path)
      assert File.exist?(@application.resume_pdf_path)
    end
  end

  def test_generate_resume_pdf_raises_error_if_markdown_missing
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    error = assert_raises(Jojo::Commands::Pdf::Converter::SourceFileNotFoundError) do
      generator.generate_resume_pdf
    end

    assert_includes error.message, "resume.md not found"
  end

  def test_generate_resume_pdf_raises_pandoc_error_if_pandoc_fails
    File.write(@application.resume_path, "# My Resume")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    generator.stub(:system, false) do
      assert_raises(Jojo::Commands::Pdf::Converter::PandocExecutionError) do
        generator.generate_resume_pdf
      end
    end
  end

  def test_generate_resume_pdf_raises_wkhtmltopdf_error_if_wkhtmltopdf_fails
    File.write(@application.resume_path, "# My Resume")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    call_count = 0
    generator.stub(:system, lambda { |_cmd|
      call_count += 1
      call_count == 1  # true on first call (pandoc), false on second (wkhtmltopdf)
    }) do
      assert_raises(Jojo::Commands::Pdf::Converter::WkhtmltopdfExecutionError) do
        generator.generate_resume_pdf
      end
    end
  end

  # -- generate_cover_letter_pdf --

  def test_generate_cover_letter_pdf_creates_html_and_pdf_files
    File.write(@application.cover_letter_path, "# Cover Letter\n\nContent here")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    call_count = 0
    generator.stub(:system, lambda { |_cmd|
      call_count += 1
      FileUtils.touch(@application.cover_letter_html_path) if call_count == 1
      FileUtils.touch(@application.cover_letter_pdf_path) if call_count == 2
      true
    }) do
      generator.generate_cover_letter_pdf
      assert File.exist?(@application.cover_letter_html_path)
      assert File.exist?(@application.cover_letter_pdf_path)
    end
  end

  def test_generate_cover_letter_pdf_raises_error_if_markdown_missing
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    error = assert_raises(Jojo::Commands::Pdf::Converter::SourceFileNotFoundError) do
      generator.generate_cover_letter_pdf
    end

    assert_includes error.message, "cover letter.md not found"
  end

  # -- generate_all --

  def test_generate_all_creates_html_and_pdf_for_both_documents
    File.write(@application.resume_path, "# Resume")
    File.write(@application.cover_letter_path, "# Cover Letter")
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    call_count = 0
    generator.stub(:system, lambda { |_cmd|
      call_count += 1
      case call_count
      when 1 then FileUtils.touch(@application.resume_html_path)
      when 2 then FileUtils.touch(@application.resume_pdf_path)
      when 3 then FileUtils.touch(@application.cover_letter_html_path)
      when 4 then FileUtils.touch(@application.cover_letter_pdf_path)
      end
      true
    }) do
      Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
        Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:check!, true) do
          result = generator.generate_all
          assert_equal 2, result[:generated].length
          assert_includes result[:generated], :resume
          assert_includes result[:generated], :cover_letter
        end
      end
    end
  end

  def test_generate_all_skips_missing_files
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
      Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:check!, true) do
        result = generator.generate_all
        assert_empty result[:generated]
        assert_equal 2, result[:skipped].length
      end
    end
  end

  # -- verbose mode --

  def test_verbose_mode_outputs_both_pandoc_and_wkhtmltopdf_commands
    File.write(@application.resume_path, "# Resume")
    output = StringIO.new
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: true, output: output)

    generator.stub(:system, true) do
      generator.generate_resume_pdf
      assert_includes output.string, "pandoc"
      assert_includes output.string, "wkhtmltopdf"
    end
  end
end

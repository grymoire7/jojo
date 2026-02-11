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

  def test_generate_resume_pdf_creates_pdf_file
    # Create a markdown resume
    File.write(@application.resume_path, "# My Resume\n\nContent here")

    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    # Stub PandocChecker.check! and system call
    generator.stub(:system, lambda { |cmd|
      FileUtils.touch(@application.resume_pdf_path)
      true
    }) do
      Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
        generator.generate_resume_pdf
        assert_equal true, File.exist?(@application.resume_pdf_path)
      end
    end
  end

  def test_generate_resume_pdf_raises_error_if_markdown_missing
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    error = assert_raises(Jojo::Commands::Pdf::Converter::SourceFileNotFoundError) do
      generator.generate_resume_pdf
    end

    assert_includes error.message, "resume.md not found"
  end

  # -- generate_cover_letter_pdf --

  def test_generate_cover_letter_pdf_creates_pdf_file
    # Create a markdown cover letter
    File.write(@application.cover_letter_path, "# Cover Letter\n\nContent here")

    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    generator.stub(:system, lambda { |cmd|
      FileUtils.touch(@application.cover_letter_pdf_path)
      true
    }) do
      Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
        generator.generate_cover_letter_pdf
        assert_equal true, File.exist?(@application.cover_letter_pdf_path)
      end
    end
  end

  # -- generate_all --

  def test_generate_all_creates_both_pdfs
    File.write(@application.resume_path, "# Resume")
    File.write(@application.cover_letter_path, "# Cover Letter")

    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    call_count = 0
    generator.stub(:system, lambda { |cmd|
      if call_count == 0
        FileUtils.touch(@application.resume_pdf_path)
      else
        FileUtils.touch(@application.cover_letter_pdf_path)
      end
      call_count += 1
      true
    }) do
      Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
        result = generator.generate_all

        assert_equal 2, result[:generated].length
        assert_includes result[:generated], :resume
        assert_includes result[:generated], :cover_letter
      end
    end
  end

  def test_generate_all_skips_missing_files
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: false)

    Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
      result = generator.generate_all

      assert_empty result[:generated]
      assert_equal 2, result[:skipped].length
    end
  end

  # -- verbose mode --

  def test_verbose_mode_outputs_pandoc_command
    File.write(@application.resume_path, "# Resume")

    output = StringIO.new
    generator = Jojo::Commands::Pdf::Converter.new(@application, verbose: true, output: output)

    generator.stub(:system, true) do
      Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
        generator.generate_resume_pdf
        assert_includes output.string, "pandoc"
      end
    end
  end
end

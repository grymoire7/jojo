require "test_helper"
require "jojo/pdf_converter"
require "jojo/employer"
require "tmpdir"

class PdfConverterTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @employer = Jojo::Employer.new("test-employer")
    @employer.instance_variable_set(:@base_path, @tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_generate_resume_pdf_creates_pdf_file
    # Create a markdown resume
    File.write(@employer.resume_path, "# My Resume\n\nContent here")

    generator = Jojo::PdfConverter.new(@employer, verbose: false)

    # Mock Pandoc being available
    Jojo::PandocChecker.stub :check!, true do
      # Mock system call to create the PDF file
      generator.stub :system, lambda { |cmd|
        # Extract output path from command and create the file
        FileUtils.touch(@employer.resume_pdf_path)
        true
      } do
        generator.generate_resume_pdf

        assert File.exist?(@employer.resume_pdf_path)
      end
    end
  end

  def test_generate_cover_letter_pdf_creates_pdf_file
    # Create a markdown cover letter
    File.write(@employer.cover_letter_path, "# Cover Letter\n\nContent here")

    generator = Jojo::PdfConverter.new(@employer, verbose: false)

    Jojo::PandocChecker.stub :check!, true do
      generator.stub :system, lambda { |cmd|
        # Extract output path from command and create the file
        FileUtils.touch(@employer.cover_letter_pdf_path)
        true
      } do
        generator.generate_cover_letter_pdf

        assert File.exist?(@employer.cover_letter_pdf_path)
      end
    end
  end

  def test_generate_all_creates_both_pdfs
    File.write(@employer.resume_path, "# Resume")
    File.write(@employer.cover_letter_path, "# Cover Letter")

    generator = Jojo::PdfConverter.new(@employer, verbose: false)

    Jojo::PandocChecker.stub :check!, true do
      call_count = 0
      generator.stub :system, lambda { |cmd|
        # Create the appropriate PDF file based on the call
        if call_count == 0
          FileUtils.touch(@employer.resume_pdf_path)
        else
          FileUtils.touch(@employer.cover_letter_pdf_path)
        end
        call_count += 1
        true
      } do
        result = generator.generate_all

        assert_equal 2, result[:generated].length
        assert_includes result[:generated], :resume
        assert_includes result[:generated], :cover_letter
      end
    end
  end

  def test_generate_all_skips_missing_files
    # Don't create any files

    generator = Jojo::PdfConverter.new(@employer, verbose: false)

    Jojo::PandocChecker.stub :check!, true do
      result = generator.generate_all

      assert_empty result[:generated]
      assert_equal 2, result[:skipped].length
    end
  end

  def test_generate_resume_raises_error_if_markdown_missing
    generator = Jojo::PdfConverter.new(@employer, verbose: false)

    error = assert_raises(Jojo::PdfConverter::SourceFileNotFoundError) do
      generator.generate_resume_pdf
    end

    assert_includes error.message, "resume.md not found"
  end

  def test_verbose_mode_outputs_pandoc_command
    File.write(@employer.resume_path, "# Resume")

    output = StringIO.new
    generator = Jojo::PdfConverter.new(@employer, verbose: true, output: output)

    Jojo::PandocChecker.stub :check!, true do
      generator.stub :system, true do
        generator.generate_resume_pdf

        assert_includes output.string, "pandoc"
      end
    end
  end
end

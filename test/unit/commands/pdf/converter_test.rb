require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/pdf/converter"
require_relative "../../../../lib/jojo/employer"
require "tmpdir"

describe Jojo::Commands::Pdf::Converter do
  before do
    @tmpdir = Dir.mktmpdir
    @employer = Jojo::Employer.new("test-employer")
    @employer.instance_variable_set(:@base_path, @tmpdir)
  end

  after do
    FileUtils.rm_rf(@tmpdir)
  end

  describe "#generate_resume_pdf" do
    it "creates pdf file" do
      # Create a markdown resume
      File.write(@employer.resume_path, "# My Resume\n\nContent here")

      generator = Jojo::Commands::Pdf::Converter.new(@employer, verbose: false)

      # Stub PandocChecker.check! and system call
      generator.stub(:system, lambda { |cmd|
        FileUtils.touch(@employer.resume_pdf_path)
        true
      }) do
        Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
          generator.generate_resume_pdf
          _(File.exist?(@employer.resume_pdf_path)).must_equal true
        end
      end
    end

    it "raises error if markdown missing" do
      generator = Jojo::Commands::Pdf::Converter.new(@employer, verbose: false)

      error = assert_raises(Jojo::Commands::Pdf::Converter::SourceFileNotFoundError) do
        generator.generate_resume_pdf
      end

      _(error.message).must_include "resume.md not found"
    end
  end

  describe "#generate_cover_letter_pdf" do
    it "creates pdf file" do
      # Create a markdown cover letter
      File.write(@employer.cover_letter_path, "# Cover Letter\n\nContent here")

      generator = Jojo::Commands::Pdf::Converter.new(@employer, verbose: false)

      generator.stub(:system, lambda { |cmd|
        FileUtils.touch(@employer.cover_letter_pdf_path)
        true
      }) do
        Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
          generator.generate_cover_letter_pdf
          _(File.exist?(@employer.cover_letter_pdf_path)).must_equal true
        end
      end
    end
  end

  describe "#generate_all" do
    it "creates both pdfs" do
      File.write(@employer.resume_path, "# Resume")
      File.write(@employer.cover_letter_path, "# Cover Letter")

      generator = Jojo::Commands::Pdf::Converter.new(@employer, verbose: false)

      call_count = 0
      generator.stub(:system, lambda { |cmd|
        if call_count == 0
          FileUtils.touch(@employer.resume_pdf_path)
        else
          FileUtils.touch(@employer.cover_letter_pdf_path)
        end
        call_count += 1
        true
      }) do
        Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
          result = generator.generate_all

          _(result[:generated].length).must_equal 2
          _(result[:generated]).must_include :resume
          _(result[:generated]).must_include :cover_letter
        end
      end
    end

    it "skips missing files" do
      generator = Jojo::Commands::Pdf::Converter.new(@employer, verbose: false)

      Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
        result = generator.generate_all

        _(result[:generated]).must_be_empty
        _(result[:skipped].length).must_equal 2
      end
    end
  end

  describe "verbose mode" do
    it "outputs pandoc command" do
      File.write(@employer.resume_path, "# Resume")

      output = StringIO.new
      generator = Jojo::Commands::Pdf::Converter.new(@employer, verbose: true, output: output)

      generator.stub(:system, true) do
        Jojo::Commands::Pdf::PandocChecker.stub(:check!, true) do
          generator.generate_resume_pdf
          _(output.string).must_include "pandoc"
        end
      end
    end
  end
end

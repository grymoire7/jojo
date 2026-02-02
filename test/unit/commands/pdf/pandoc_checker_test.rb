require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/pdf/pandoc_checker"

describe Jojo::Commands::Pdf::PandocChecker do
  describe ".available?" do
    it "returns true when pandoc is installed" do
      Jojo::Commands::Pdf::PandocChecker.stub(:system, true) do
        _(Jojo::Commands::Pdf::PandocChecker.available?).must_equal true
      end
    end

    it "returns false when pandoc is not installed" do
      Jojo::Commands::Pdf::PandocChecker.stub(:system, false) do
        _(Jojo::Commands::Pdf::PandocChecker.available?).must_equal false
      end
    end
  end

  describe ".version" do
    it "returns version string when installed" do
      Jojo::Commands::Pdf::PandocChecker.stub(:available?, true) do
        Jojo::Commands::Pdf::PandocChecker.stub(:`, "pandoc 3.1.11\n") do
          _(Jojo::Commands::Pdf::PandocChecker.version).must_equal "3.1.11"
        end
      end
    end

    it "returns nil when not installed" do
      Jojo::Commands::Pdf::PandocChecker.stub(:available?, false) do
        _(Jojo::Commands::Pdf::PandocChecker.version).must_be_nil
      end
    end
  end

  describe ".check!" do
    it "raises error when not installed" do
      Jojo::Commands::Pdf::PandocChecker.stub(:available?, false) do
        error = assert_raises(Jojo::Commands::Pdf::PandocChecker::PandocNotFoundError) do
          Jojo::Commands::Pdf::PandocChecker.check!
        end
        _(error.message).must_include "Pandoc is not installed"
      end
    end

    it "returns true when installed" do
      Jojo::Commands::Pdf::PandocChecker.stub(:available?, true) do
        _(Jojo::Commands::Pdf::PandocChecker.check!).must_equal true
      end
    end
  end
end

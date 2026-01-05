module Jojo
  # Utility module for formatting resume data into text format
  module ResumeDataFormatter
    def self.format(data)
      # Convert structured resume_data to readable text format for prompts
      output = []
      output << "# #{data["name"]}"
      output << "#{data["email"]} | #{data["location"]}"
      output << ""
      output << "## Summary"
      output << data["summary"]
      output << ""
      output << "## Skills"
      output << data["skills"].join(", ")
      output << ""
      output << "## Experience"
      data["experience"].each do |exp|
        output << "### #{exp["title"]} at #{exp["company"]}"
        output << exp["description"]
        if exp["technologies"]
          output << "Technologies: #{exp["technologies"].join(", ")}"
        end
        output << ""
      end
      output << "## Projects"
      if data["projects"] && !data["projects"].empty?
        data["projects"].each do |proj|
          output << "### #{proj["name"]}"
          output << proj["description"] if proj["description"]
          if proj["skills"] && !proj["skills"].empty?
            output << "Skills: #{proj["skills"].join(", ")}"
          end
          output << ""
        end
      else
        output << "No projects listed."
      end
      output.join("\n")
    end
  end
end

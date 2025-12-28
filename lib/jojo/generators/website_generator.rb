require 'yaml'
require 'erb'
require 'fileutils'
require 'json'
require_relative '../prompts/website_prompt'
require_relative '../project_loader'
require_relative '../project_selector'
require_relative '../recommendation_parser'

module Jojo
  module Generators
    class WebsiteGenerator
      attr_reader :employer, :ai_client, :config, :verbose, :template_name, :inputs_path

      def initialize(employer, ai_client, config:, template: 'default', verbose: false, inputs_path: 'inputs')
        @employer = employer
        @ai_client = ai_client
        @config = config
        @template_name = template
        @verbose = verbose
        @inputs_path = inputs_path
      end

      def generate
        log "Gathering inputs for website generation..."
        inputs = gather_inputs

        log "Generating personalized branding statement using AI..."
        branding_statement = generate_branding_statement(inputs)

        log "Loading relevant projects..."
        projects = load_projects
        projects = process_project_images(projects)

        log "Loading and annotating job description..."
        annotated_job_description = annotate_job_description

        log "Loading recommendations..."
        recommendations = load_recommendations

        log "Loading FAQs..."
        faqs = load_faqs

        log "Preparing template variables..."
        template_vars = prepare_template_vars(branding_statement, inputs, projects, annotated_job_description, recommendations, faqs)

        log "Rendering HTML template (#{template_name})..."
        html = render_template(template_vars)

        log "Copying branding image if available..."
        copy_branding_image

        log "Saving website to #{employer.index_html_path}..."
        save_website(html)

        log "Website generation complete!"
        html
      end

      private

      def gather_inputs
        # Read job description (REQUIRED)
        unless File.exist?(employer.job_description_path)
          raise "Job description not found at #{employer.job_description_path}"
        end
        job_description = File.read(employer.job_description_path)

        # Read tailored resume (REQUIRED)
        unless File.exist?(employer.resume_path)
          raise "Resume not found at #{employer.resume_path}. Run 'jojo resume' first."
        end
        resume = File.read(employer.resume_path)

        # Read research (OPTIONAL)
        research = read_research

        # Read job details (OPTIONAL)
        job_details = read_job_details

        {
          job_description: job_description,
          resume: resume,
          research: research,
          job_details: job_details,
          company_name: employer.name,
          company_slug: employer.slug
        }
      end

      def read_research
        unless File.exist?(employer.research_path)
          log "Warning: Research not found at #{employer.research_path}, branding will be less targeted"
          return nil
        end

        File.read(employer.research_path)
      end

      def read_job_details
        unless File.exist?(employer.job_details_path)
          return nil
        end

        YAML.load_file(employer.job_details_path)
      rescue => e
        log "Warning: Could not parse job details: #{e.message}"
        nil
      end

      def generate_branding_statement(inputs)
        prompt = Prompts::Website.generate_branding_statement(
          job_description: inputs[:job_description],
          resume: inputs[:resume],
          company_name: inputs[:company_name],
          seeker_name: config.seeker_name,
          voice_and_tone: config.voice_and_tone,
          research: inputs[:research],
          job_details: inputs[:job_details]
        )

        ai_client.generate_text(prompt)
      end

      def prepare_template_vars(branding_statement, inputs, projects = [], annotated_job_description = nil, recommendations = nil, faqs = nil)
        # Extract job title from job_details if available
        job_title = inputs[:job_details] ? inputs[:job_details]['job_title'] : nil

        # Check for branding image
        branding_image_info = find_branding_image

        # Check for CTA link
        cta_link = config.website_cta_link
        if cta_link.nil? || cta_link.strip.empty?
          log "Warning: No website CTA link configured in config.yml. CTA button will not be displayed."
          log "  Add website.cta_link to config.yml (e.g., Calendly URL or mailto link)"
        end

        {
          seeker_name: config.seeker_name,
          company_name: inputs[:company_name],
          company_slug: inputs[:company_slug],
          job_title: job_title,
          branding_statement: branding_statement,
          cta_text: config.website_cta_text,
          cta_link: cta_link,
          has_branding_image: branding_image_info[:exists],
          branding_image_path: branding_image_info[:relative_path],
          base_url: config.base_url,
          projects: projects,
          annotated_job_description: annotated_job_description,
          recommendations: recommendations,
          faqs: faqs
        }
      end

      def render_template(vars)
        template_path = File.join('templates', 'website', "#{template_name}.html.erb")

        unless File.exist?(template_path)
          raise "Template not found: #{template_path}. Available templates: #{available_templates.join(', ')}"
        end

        template_content = File.read(template_path)

        # Create binding with template variables
        seeker_name = vars[:seeker_name]
        company_name = vars[:company_name]
        company_slug = vars[:company_slug]
        job_title = vars[:job_title]
        branding_statement = vars[:branding_statement]
        cta_text = vars[:cta_text]
        cta_link = vars[:cta_link]
        has_branding_image = vars[:has_branding_image]
        branding_image_path = vars[:branding_image_path]
        base_url = vars[:base_url]
        projects = vars[:projects]
        annotated_job_description = vars[:annotated_job_description]
        recommendations = vars[:recommendations]
        faqs = vars[:faqs]

        ERB.new(template_content).result(binding)
      end

      def find_branding_image
        # Check for branding image in inputs directory
        image_extensions = %w[.jpg .jpeg .png .gif]
        image_extensions.each do |ext|
          path = File.join(inputs_path, "branding_image#{ext}")
          if File.exist?(path)
            return {
              exists: true,
              source_path: path,
              relative_path: "branding_image#{ext}",
              extension: ext
            }
          end
        end

        { exists: false, source_path: nil, relative_path: nil, extension: nil }
      end

      def copy_branding_image
        image_info = find_branding_image

        unless image_info[:exists]
          log "No branding image found in #{inputs_path}/"
          return false
        end

        # Ensure website directory exists
        FileUtils.mkdir_p(employer.website_path)

        # Copy image to website directory
        dest_path = File.join(employer.website_path, image_info[:relative_path])
        FileUtils.cp(image_info[:source_path], dest_path)

        log "Copied branding image: #{image_info[:source_path]} -> #{dest_path}"
        true
      end

      def save_website(html)
        # Ensure website directory exists
        FileUtils.mkdir_p(employer.website_path)

        # Write HTML file
        File.write(employer.index_html_path, html)
      end

      def available_templates
        template_dir = 'templates/website'
        return [] unless Dir.exist?(template_dir)

        Dir.glob(File.join(template_dir, '*.html.erb')).map do |path|
          File.basename(path, '.html.erb')
        end
      end

      def log(message)
        puts "  [WebsiteGenerator] #{message}" if verbose
      end

      def load_projects
        projects_path = File.join(inputs_path, 'projects.yml')
        return [] unless File.exist?(projects_path)

        loader = ProjectLoader.new(projects_path)
        all_projects = loader.load

        selector = ProjectSelector.new(employer, all_projects)
        selector.select_for_landing_page(limit: 5)
      rescue ProjectLoader::ValidationError => e
        log "Warning: Projects validation failed: #{e.message}"
        []
      end

      def process_project_images(projects)
        projects.map do |project|
          project = project.dup

          if project[:image]
            if project[:image].start_with?('http://', 'https://')
              # URL: use directly
              project[:image_url] = project[:image]
            else
              # File path: copy to website/images/
              src = File.join(Dir.pwd, project[:image])

              if File.exist?(src)
                dest_dir = File.join(employer.website_path, 'images')
                FileUtils.mkdir_p(dest_dir)

                filename = File.basename(project[:image])
                dest = File.join(dest_dir, filename)
                FileUtils.cp(src, dest)

                project[:image_url] = "images/#{filename}"
              else
                log "Warning: Project image not found: #{project[:image]}"
              end
            end
          end

          project
        end
      end

      def annotate_job_description
        # Load annotations JSON
        unless File.exist?(employer.job_description_annotations_path)
          log "No annotations found at #{employer.job_description_annotations_path}"
          return nil
        end

        annotations = load_annotations
        return nil if annotations.nil? || annotations.empty?

        # Load job description
        unless File.exist?(employer.job_description_path)
          log "Warning: Job description not found, cannot annotate"
          return nil
        end

        job_description_md = File.read(employer.job_description_path)

        # Convert to HTML and inject annotations
        annotated_html = inject_annotations(job_description_md, annotations)
        annotated_html
      rescue => e
        log "Error annotating job description: #{e.message}"
        nil
      end

      def load_annotations
        json_content = File.read(employer.job_description_annotations_path)
        JSON.parse(json_content, symbolize_names: true)
      rescue JSON::ParserError => e
        log "Error: Malformed annotations JSON: #{e.message}"
        nil
      end

      def inject_annotations(markdown_text, annotations)
        require 'cgi'

        # Convert markdown to HTML paragraphs
        html = markdown_to_html(markdown_text)

        # Inject each annotation
        annotations.each do |annotation|
          text = annotation[:text]
          match = CGI.escapeHTML(annotation[:match])
          tier = annotation[:tier]

          # Replace all occurrences
          pattern = Regexp.new(Regexp.escape(text))
          replacement = %(<span class="annotated" data-tier="#{tier}" data-match="#{match}">#{text}</span>)

          html.gsub!(pattern, replacement)
        end

        html
      end

      def markdown_to_html(markdown)
        # Simple markdown to HTML conversion
        paragraphs = markdown.split("\n\n").map(&:strip).reject(&:empty?)

        paragraphs.map do |para|
          # Convert bold
          para = para.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')
          # Convert italic
          para = para.gsub(/\*([^*]+)\*/, '<em>\1</em>')
          # Convert links
          para = para.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2">\1</a>')

          "<p>#{para}</p>"
        end.join("\n")
      end

      def load_recommendations
        recommendations_path = File.join(inputs_path, 'recommendations.md')

        unless File.exist?(recommendations_path)
          log "No recommendations found at #{recommendations_path}"
          return nil
        end

        parser = RecommendationParser.new(recommendations_path)
        recommendations = parser.parse

        if recommendations.nil? || recommendations.empty?
          log "Warning: No valid recommendations found in #{recommendations_path}"
          return nil
        end

        log "Loaded #{recommendations.size} recommendation(s)"
        recommendations
      rescue => e
        log "Error loading recommendations: #{e.message}"
        nil
      end

      def load_faqs
        return nil unless File.exist?(employer.faq_path)

        faq_data = File.read(employer.faq_path)
        JSON.parse(faq_data, symbolize_names: true)
      rescue JSON::ParserError => e
        log "Error: Could not parse FAQ file: #{e.message}"
        nil
      rescue => e
        log "Error loading FAQs: #{e.message}"
        nil
      end
    end
  end
end

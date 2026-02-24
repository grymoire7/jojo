# lib/jojo/commands/website/generator.rb
require "yaml"
require "erb"
require "fileutils"
require "json"
require_relative "../../resume_data_loader"

module Jojo
  module Commands
    module Website
      class Generator
        attr_reader :application, :ai_client, :config, :verbose, :template_name, :inputs_path, :overwrite_flag, :cli_instance

        def initialize(application, ai_client, config:, template: "default", verbose: false, inputs_path: "inputs", overwrite_flag: nil, cli_instance: nil)
          @application = application
          @ai_client = ai_client
          @config = config
          @template_name = template
          @verbose = verbose
          @inputs_path = inputs_path
          @overwrite_flag = overwrite_flag
          @cli_instance = cli_instance
        end

        def generate
          log "Gathering inputs for website generation..."
          inputs = gather_inputs

          log "Loading branding statement from file..."
          branding_statement = load_branding_statement

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

          log "Copying template assets (CSS, JS, SVG)..."
          copy_template_assets

          log "Saving website to #{application.index_html_path}..."
          save_website(html)

          log "Website generation complete!"
          html
        end

        private

        def gather_inputs
          # Read job description (REQUIRED)
          unless File.exist?(application.job_description_path)
            raise "Job description not found at #{application.job_description_path}"
          end
          job_description = File.read(application.job_description_path)

          # Read tailored resume (REQUIRED)
          unless File.exist?(application.resume_path)
            raise "Resume not found at #{application.resume_path}. Run 'jojo resume' first."
          end
          resume = File.read(application.resume_path)

          # Read research (OPTIONAL)
          research = read_research

          # Read job details (OPTIONAL)
          job_details = read_job_details

          {
            job_description: job_description,
            resume: resume,
            research: research,
            job_details: job_details,
            company_name: application.company_name,
            company_slug: application.slug
          }
        end

        def read_research
          unless File.exist?(application.research_path)
            log "Warning: Research not found at #{application.research_path}, branding will be less targeted"
            return nil
          end

          File.read(application.research_path)
        end

        def read_job_details
          unless File.exist?(application.job_details_path)
            return nil
          end

          YAML.load_file(application.job_details_path)
        rescue => e
          log "Warning: Could not parse job details: #{e.message}"
          nil
        end

        def load_branding_statement
          unless File.exist?(application.branding_path) && !File.read(application.branding_path).strip.empty?
            raise "branding.md not found for '#{application.slug}'\nRun 'jojo branding -s #{application.slug}' first to generate branding statement."
          end

          File.read(application.branding_path)
        end

        def prepare_template_vars(branding_statement, inputs, projects = [], annotated_job_description = nil, recommendations = nil, faqs = nil)
          # Extract job title from job_details if available
          job_title = inputs[:job_details] ? inputs[:job_details]["job_title"] : nil

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
          template_path = File.join("templates", "website", "#{template_name}.html.erb")

          unless File.exist?(template_path)
            raise "Template not found: #{template_path}. Available templates: #{available_templates.join(", ")}"
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

          {exists: false, source_path: nil, relative_path: nil, extension: nil}
        end

        def copy_branding_image
          image_info = find_branding_image

          unless image_info[:exists]
            log "No branding image found in #{inputs_path}/"
            return false
          end

          # Ensure website directory exists
          FileUtils.mkdir_p(application.website_path)

          # Copy image to website directory
          dest_path = File.join(application.website_path, image_info[:relative_path])
          FileUtils.cp(image_info[:source_path], dest_path)

          log "Copied branding image: #{image_info[:source_path]} -> #{dest_path}"
          true
        end

        def copy_template_assets
          # Ensure website directory exists
          FileUtils.mkdir_p(application.website_path)

          # Build Tailwind CSS
          build_tailwind_css

          # Copy static assets (CSS is now built by Tailwind, not copied)
          template_dir = File.join("templates", "website")
          assets = ["script.js", "icons.svg"]

          assets.each do |asset|
            source = File.join(template_dir, asset)
            dest = File.join(application.website_path, asset)

            if File.exist?(source)
              FileUtils.cp(source, dest)
              log "Copied #{asset} to #{application.website_path}"
            else
              log "Warning: Asset not found: #{source}"
            end
          end
        end

        def build_tailwind_css
          template_dir = File.expand_path(File.join("templates", "website"))
          input_css = File.join(template_dir, "tailwind", "input.css")
          output_css = File.expand_path(File.join(application.website_path, "styles.css"))

          node_modules = File.join(template_dir, "node_modules")
          unless Dir.exist?(node_modules)
            raise "node_modules not found in #{template_dir}. Run: cd #{template_dir} && npm install"
          end

          tailwind_bin = File.join(node_modules, ".bin", "tailwindcss")
          unless File.exist?(tailwind_bin)
            raise "tailwindcss not found in node_modules. Run: cd #{template_dir} && npm install"
          end

          cmd = "#{tailwind_bin} -i #{input_css} -o #{output_css} --minify"
          log "Building Tailwind CSS: #{cmd}"

          require "open3"

          # Run from template dir so DaisyUI plugin resolves from local node_modules.
          # Capture output so version banners don't pollute the user's terminal;
          # only print on failure so error details are not lost.
          build_output, success = Dir.chdir(template_dir) do
            if defined?(Bundler)
              Bundler.with_unbundled_env do
                out, status = Open3.capture2e(cmd)
                [out, status.success?]
              end
            else
              out, status = Open3.capture2e(cmd)
              [out, status.success?]
            end
          end

          unless success
            warn build_output
            raise "Tailwind CSS build failed. Check your template for syntax errors."
          end
        end

        def save_website(html)
          # Ensure website directory exists
          FileUtils.mkdir_p(application.website_path)

          # Write HTML file
          if cli_instance
            cli_instance.with_overwrite_check(application.index_html_path, overwrite_flag) do
              File.write(application.index_html_path, html)
            end
          else
            File.write(application.index_html_path, html)
          end
        end

        def available_templates
          template_dir = "templates/website"
          return [] unless Dir.exist?(template_dir)

          Dir.glob(File.join(template_dir, "*.html.erb")).map do |path|
            File.basename(path, ".html.erb")
          end
        end

        def log(message)
          puts "  [WebsiteGenerator] #{message}" if verbose
        end

        def load_projects
          resume_data_path = File.join(inputs_path, "resume_data.yml")
          return [] unless File.exist?(resume_data_path)

          loader = ResumeDataLoader.new(resume_data_path)
          resume_data = loader.load

          projects = resume_data["projects"] || []

          # Convert to symbol keys for consistency
          projects.map { |p| p.transform_keys(&:to_sym) }
        rescue ResumeDataLoader::LoadError, ResumeDataLoader::ValidationError => e
          log "Warning: Could not load projects from resume_data.yml: #{e.message}"
          []
        end

        def process_project_images(projects)
          projects.map do |project|
            project = project.dup

            if project[:image]
              if project[:image].start_with?("http://", "https://")
                # URL: use directly
                project[:image_url] = project[:image]
              else
                # File path: copy to website/images/
                src = File.join(inputs_path, project[:image])

                if File.exist?(src)
                  dest_dir = File.join(application.website_path, "images")
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
          unless File.exist?(application.job_description_annotations_path)
            log "No annotations found at #{application.job_description_annotations_path}"
            return nil
          end

          annotations = load_annotations
          return nil if annotations.nil? || annotations.empty?

          # Load job description
          unless File.exist?(application.job_description_path)
            log "Warning: Job description not found, cannot annotate"
            return nil
          end

          job_description_md = File.read(application.job_description_path)

          # Convert to HTML and inject annotations
          inject_annotations(job_description_md, annotations)
        rescue => e
          log "Error annotating job description: #{e.message}"
          nil
        end

        def load_annotations
          json_content = File.read(application.job_description_annotations_path)
          JSON.parse(json_content, symbolize_names: true)
        rescue JSON::ParserError => e
          log "Error: Malformed annotations JSON: #{e.message}"
          nil
        end

        def inject_annotations(markdown_text, annotations)
          require "cgi"

          # Convert markdown to HTML paragraphs
          html = markdown_to_html(markdown_text)

          # Sort annotations by text length (longest first) to reduce overlapping issues
          sorted_annotations = annotations.sort_by { |a| -a[:text].length }

          # Track annotated regions as [start_pos, end_pos] to prevent overlaps
          annotated_regions = []

          sorted_annotations.each do |annotation|
            text = annotation[:text]
            match = CGI.escapeHTML(annotation[:match])
            tier = annotation[:tier]

            # Find all occurrences of this text
            offset = 0
            while (pos = html.index(text, offset))
              region_start = pos
              region_end = pos + text.length

              # Check if this region overlaps with any already-annotated region
              overlaps = annotated_regions.any? do |r_start, r_end|
                !(region_end <= r_start || region_start >= r_end)
              end

              if overlaps
                # Skip this occurrence - it's already inside an annotation
                offset = region_end
                next
              end

              # Insert the annotation span
              html = html[0...region_start] +
                %(<span class="annotated" data-tier="#{tier}" data-match="#{match}">#{text}</span>) +
                html[region_end..]

              # Track this region (accounting for inserted span tags)
              inserted_tag_length = %(<span class="annotated" data-tier="#{tier}" data-match="#{match}">).length
              closing_tag_length = 7  # </span>
              total_inserted = inserted_tag_length + closing_tag_length

              annotated_regions << [region_start, region_end + total_inserted]

              # Adjust all existing regions to account for the insertion
              annotated_regions.each do |r|
                if r[0] > region_start
                  r[0] += total_inserted
                  r[1] += total_inserted
                end
              end

              # Move offset past the annotated region
              offset = region_end + total_inserted
            end
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
          resume_data_path = File.join(inputs_path, "resume_data.yml")

          unless File.exist?(resume_data_path)
            log "No resume data found at #{resume_data_path}"
            return nil
          end

          loader = ResumeDataLoader.new(resume_data_path)
          resume_data = loader.load

          recommendations = resume_data["recommendations"]
          return nil if recommendations.nil? || recommendations.empty?

          # Convert to symbol keys for template compatibility
          recommendations.map { |r| r.transform_keys(&:to_sym) }
        rescue => e
          log "Error loading recommendations: #{e.message}"
          nil
        end

        def load_faqs
          return nil unless File.exist?(application.faq_path)

          faq_data = File.read(application.faq_path)
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
end

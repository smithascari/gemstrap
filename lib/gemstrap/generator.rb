require 'pathname'
require 'fileutils'

require 'gemstrap/template'
require 'gemstrap/colorize'

module Gemstrap
  class Generator
    include FileUtils
    include Colorize

    def run(args)
      options.merge!(args)
      puts "   creating gem #{color(gem_name, YELLOW)}"
      say_args(args)
      generate!
    rescue => e
      puts e.message
      puts e.backtrace.join("\n")
    end

    def method_missing(method, *args, &block)
      return context[method] if context.include?(method)
      super
    end

    private

    def options
      @options ||= {
        gem_name: '',
        authors: [],
        authors_emails: [],
        description: '',
        summary: '',
        github_user: '',
        homepage: ''
      }
    end

    def context
      options[:templates] = Pathname.new(File.dirname(__FILE__)).join('template')
      options[:path]      = Pathname.new('.').join(options[:gem_name])
      options[:lib_path]  = options[:path].join('lib')
      options[:spec_path] = options[:path].join('spec')
      options[:gem_module] = gem_name_to_module_name
      options
    end

    def generate!
      puts '   generate'
      mkdir_p(path)
      generate_root_files
      generate_lib_files
      mkdir_p(spec_path)
      cp(templates.join('Rakefile'), path)
    end

    def generate_root_files
      %w(.gitignore Rakefile Gemfile).each do |file|
        copy_template(templates.join(file), path.join(file))
      end
      generate_file(path.join('README.md'), render_template('README.md.erb'))
      generate_file(path.join("#{gem_name}.gemspec"), render_template('gemspec.erb'))
    end

    def generate_lib_files
      [lib_path, lib_path.join(gem_name)].each { |path| mkdir_p(path) }
      generate_file(lib_path.join("#{gem_name}.rb"), render_template('lib/root.rb.erb'))
      generate_file(lib_path.join("#{gem_name}/version.rb"), render_template('lib/gem_name/version.rb.erb'))
    end

    def render_template(template_path)
      Gemstrap::Template.render(templates.join(template_path), context)
    end

    def mkdir_p(path)
      say_created(path)
      super(path)
    end

    def copy_template(from, to)
      cp(from, to)
      say_created(to)
    end

    def generate_file(path, contents)
      IO.write(path, contents)
      say_created(path)
    end

    def say_args(args)
      puts '   gem data'
      args.each do |k, v|
        k = color(k, BOLD, true)
        puts "     using   #{k.ljust(28)} => #{v}"
      end
    end

    def say_created(item)
      created_color = color('create', GREEN, true)
      puts "     #{created_color}  #{item}"
    end

    def gem_name_to_module_name
      name_parts = options[:gem_name].split('-').collect { |n| n.split('_') }
      name_parts.flatten.collect(&:capitalize).join
    end
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'pathname'
require 'tmpdir'
require 'asciidoctor'
require 'asciidoctor-pdf'
require 'asciidoctor-diagram'

root = Pathname.new(__dir__).join('../..').expand_path
sources = root.join('project/materials/labs')
output = root.join('public/labs')
options = { format: 'all', lab: ENV.fetch('LAB', '') }
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: labs.rb [--format all|html|pdf] [--lab DIRECTORY_OR_FILE] [--list]'
  opts.on('--format FORMAT', %w[all html pdf]) { |v| options[:format] = v }
  opts.on('--lab LAB') { |v| options[:lab] = v }
  opts.on('--list') { options[:list] = true }
end

begin
  parser.parse!
  raise ArgumentError, "Unexpected arguments: #{ARGV.join(' ')}" unless ARGV.empty?

  # Only documents with a level-zero title are entry points; include fragments
  # and diagram resources may also use the .adoc extension.
  labs = sources.glob('**/*.adoc').sort.select do |path|
    path.read(encoding: 'UTF-8').match?(/^=\s+\S/)
  end
  unless options[:lab].empty?
    selected = sources.join(options[:lab]).cleanpath
    labs.select! { |path| path == selected || path.dirname == selected }
  end
  raise ArgumentError, 'No matching lab documents found (use make labs-list).' if labs.empty?

  if options[:list]
    puts labs.map { |path| path.relative_path_from(sources) }
    exit
  end

  # Project extensions run in the same Ruby process for both output formats.
  root.glob('project/scripts/asciidoctor/*.rb').sort.each { |path| require path.to_s }
  formats = options[:format] == 'all' ? %w[html pdf] : [options[:format]]
  labs.each do |source|
    relative = source.relative_path_from(sources)
    destination = output.join(relative.dirname)
    FileUtils.mkdir_p(destination)

    formats.each do |format|
      target = destination.join("#{source.basename('.adoc')}.#{format}")
      # Each conversion gets its own writable diagram cache; HTML embeds its
      # images, and PDF embeds them natively. No generated files enter sources.
      Dir.mktmpdir('ossec-lab-') do |scratch|
        attributes = {
          'data-uri' => '', 'webfonts!' => '', 'source-highlighter' => 'rouge',
          'diagram-cachedir' => scratch, 'imagesoutdir' => scratch,
          'pdf-theme' => root.join('project/build/labs/pdf-theme.yml').to_s,
          'pdf-fontsdir' => '/usr/share/fonts/truetype/dejavu'
        }
        attributes['icons'] = 'font' if format == 'pdf'
        logger = Asciidoctor::MemoryLogger.new
        Asciidoctor::LoggerManager.logger = logger
        staged = File.join(scratch, "lab.#{format}")
        Asciidoctor.convert_file(source.to_s, backend: format == 'pdf' ? 'pdf' : 'html5',
                                 safe: :unsafe, to_file: staged, mkdirs: true,
                                 attributes: attributes)
        logger.messages.each { |entry| warn "#{relative}: #{entry[:severity]}: #{entry[:message]}" }
        if logger.messages.any? { |entry| %i[WARN ERROR FATAL].include?(entry[:severity]) }
          raise "Conversion reported warnings/errors for #{relative} (#{format})"
        end
        FileUtils.cp(staged, target)
      end
      puts "Built #{target.relative_path_from(root)}"
    end
  end
rescue StandardError => e
  warn e.message
  exit 1
end

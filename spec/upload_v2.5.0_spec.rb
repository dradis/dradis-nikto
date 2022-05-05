require 'spec_helper'

module Dradis::Plugins
  describe 'Nikto v2.5.0 upload plugin' do
    before(:each) do
      # Stub template service
      templates_dir = File.expand_path('../../templates', __FILE__)
      expect_any_instance_of(Dradis::Plugins::TemplateService)
      .to receive(:default_templates_dir).and_return(templates_dir)

      # Init services
      plugin = Dradis::Plugins::Nikto

      @content_service = Dradis::Plugins::ContentService::Base.new(
        logger: Logger.new(STDOUT),
        plugin: plugin
      )

      @importer = Dradis::Plugins::Nikto::Importer.new(
        content_service: @content_service,
      )

      # Stub dradis-plugins methods
      #
      # They return their argument hashes as objects mimicking
      # Nodes, Issues, etc
      %w[evidence issue node note].each do |resource|
        allow(@content_service).to receive("create_#{resource}") do |args|
          OpenStruct.new(args)
        end
      end
    end

    let(:example_xml) { 'spec/fixtures/files/sample_v2.5.0.xml' }

    def run_import!
      @importer.import(file: example_xml)
    end

    it 'creates issue with references' do
      expect(@content_service).to receive(:create_issue) do |args|
        expect(args[:text]).to include("#[Title]#\n\/\: Directory indexing found.")
        expect(args[:text]).to include("#[References]#\n000000\nCVE-2006-6133\nhttps://example.com/")
        OpenStruct.new(args)
      end

      run_import!
    end
  end
end

require 'spec_helper'

module Dradis::Plugins
  describe 'Nikto upload plugin' do
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
      allow(@content_service).to receive(:create_node) do |args|
        OpenStruct.new(args)
      end
      allow(@content_service).to receive(:create_note) do |args|
        OpenStruct.new(args)
      end
      allow(@content_service).to receive(:create_issue) do |args|
        OpenStruct.new(args)
      end
      allow(@content_service).to receive(:create_evidence) do |args|
        OpenStruct.new(args)
      end
    end

    let(:example_xml) { 'spec/fixtures/files/localhost.xml' }

    def run_import!
      @importer.import(file: example_xml)
    end

    it "creates nodes as needed" do
      # Creates the Host Node
      expect(@content_service).to receive(:create_node) do |args|
        expect(args[:label]).to eq('127.0.0.1')
        expect(args[:type]).to eq(:host)
        OpenStruct.new(args)
      end.once
      run_import!
    end

    it "creates issues as needed" do
      # Creates 3 Issues
      expect(@content_service).to receive(:create_issue) do |args|
        expect(args[:text]).to include("#[Title]#\n\/\: Directory indexing found.")
        OpenStruct.new(args)
      end

      expect(@content_service).to receive(:create_issue) do |args|
        expect(args[:text]).to include("#[Title]#\nApache/2.2.16 appears to be outdated (current is at least Apache/2.2.19). Apache 1.3.42 (final release) and 2.0.64 are also current.")
        OpenStruct.new(args)
      end.once

      expect(@content_service).to receive(:create_issue) do |args|
        expect(args[:text]).to include("#[Title]#\nAllowed HTTP Methods: GET, HEAD, POST, OPTIONS")
        OpenStruct.new(args)
      end.once

      run_import!
    end

    it "creates evidence as needed" do
      # Creates 4 instances of Evidence for the 3 Issues
      expect(@content_service).to receive(:create_evidence) do |args|
        expect(args[:content]).to include("Link: http://localhost:80/")
        expect(args[:issue].text).to include("Directory indexing found.")
        expect(args[:node].label).to eq("127.0.0.1")
        OpenStruct.new(args)
      end.once

      expect(@content_service).to receive(:create_evidence) do |args|
        expect(args[:content]).to include("Link: http://localhost:80/")
        expect(args[:issue].text).to include("Apache/2.2.16 appears to be outdated (current is at least Apache/2.2.19). Apache 1.3.42 (final release) and 2.0.64 are also current.")
        expect(args[:node].label).to eq("127.0.0.1")
        OpenStruct.new(args)
      end.once

      expect(@content_service).to receive(:create_evidence) do |args|
        expect(args[:content]).to include("Link: http://localhost:80/")
        expect(args[:issue].text).to include("Allowed HTTP Methods: GET, HEAD, POST, OPTIONS")
        expect(args[:node].label).to eq("127.0.0.1")
        OpenStruct.new(args)
      end.once

      expect(@content_service).to receive(:create_evidence) do |args|
        expect(args[:content]).to include("Link: http://localhost:80/?show=http://cirt.net/rfiinc.txt??")
        expect(args[:issue].text).to include("Directory indexing found.")
        expect(args[:node].label).to eq("127.0.0.1")
        OpenStruct.new(args)
      end.once

      run_import!
    end

  end
end

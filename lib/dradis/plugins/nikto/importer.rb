module Dradis::Plugins::Nikto
  class Importer < Dradis::Plugins::Upload::Importer
    # The framework will call this function if the user selects this plugin from
    # the dropdown list and uploads a file.
    # @returns true if the operation was successful, false otherwise
    def import(params={})
      file_content = File.read( params[:file] )
      file_name = File.basename( params[:file] )

      # Hack because the Nikto file isn't correctly formatted yet
      # https://trac.assembla.com/Nikto_2/ticket/229
      xml_arr = file_content.split("\n")
      xml_arr[2,0] = "<nikto>"
      xml_arr << "</nikto>"
      xml = xml_arr.join

      logger.info{ 'Parsing Nikto output...' }
      doc = Nokogiri::XML(xml)
      logger.info{ 'Done.' }

      if doc.xpath('/nikto/niktoscan/niktoscan/scandetails').empty?
        error = "No scan results were detected in the uploaded file (/nikto/niktoscan/scandetails). Ensure you uploaded a Nikto XML report."
        logger.fatal{ error }
        content_service.create_note text: error
        return false
      end

      doc.xpath('/nikto/niktoscan/niktoscan/scandetails').each do |xml_scan|
        host_label = xml_scan['targetip']

        # Hack to include the file name in the xml
        # so we can use it in the template
        xml_scan['filename'] = file_name

        # Scan details
        logger.info{ 'Adding ' + host_label }
        host_node = content_service.create_node(label: host_label, type: :host)
        scan_text = template_service.process_template(template: 'scan', data: xml_scan)
        content_service.create_note(
          text: scan_text,
          node: host_node)

        # Add Node properties
        if host_node.respond_to?(:properties)
          host_node.set_property(:hostname, xml_scan['hostheader'])
          host_node.set_property(:ip, xml_scan['targetip'])
          host_node.set_property(:os, xml_scan['targetbanner'])
          host_node.save
        end

        # Check for SSL cert tag and add that data in as well
        unless xml_scan.at_xpath("ssl").nil?
          xml_ssl = xml_scan.at_xpath("ssl")
          ssl_text = template_service.process_template(template: 'ssl', data: xml_ssl)
          content_service.create_note(
            text: ssl_text,
            node: host_node)
        end

        # Items
        xml_scan.xpath("item").each do |xml_item|
          plugin_id = xml_item.has_attribute?("id") ? xml_item["id"] : "Unknown"
          item_text = template_service.process_template(template: 'item', data: xml_item)
          logger.info{ 'Creating Issue ID' + plugin_id }
          issue = content_service.create_issue(text: item_text, id: plugin_id)

          logger.info{ "\t\t => Creating new evidence" }
          evidence_content = template_service.process_template(template: 'evidence', data: xml_item)
          content_service.create_evidence(issue: issue, node: host_node, content: evidence_content)
        end
      end

      logger.info("All Done!")
    end
  end
end

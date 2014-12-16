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

      if doc.xpath('/nikto/niktoscan/scandetails').empty?
        error = "No scan results were detected in the uploaded file (/nikto/niktoscan/scandetails). Ensure you uploaded a Nikto XML report."
        logger.fatal{ error }
        content_service.create_note text: error
        return false
      end

      doc.xpath('/nikto/niktoscan/scandetails').each do |xml_scan|
        if xml_scan.has_attribute? "sitename"
          host_label = xml_scan['sitename']
        else
          host_label = xml_scan['siteip']
        end

        # The rand is good for debugging as it means each node is fairly unique
        # host_label = host_label + " - " + Configuration.parent_node + rand(99).to_s

        logger.info{ 'Adding ' + host_label }

        host_node = content_service.create_node(label: host_label, type: :host)

        node_text = "#[Details]#\n"
        node_text += "IP = " + xml_scan['targetip'] + "\n" if xml_scan.has_attribute? "targetip"
        node_text += "Hostname = " + xml_scan['targethostname'] + "\n" if xml_scan.has_attribute? "targethostname"
        node_text += "Port = " + xml_scan['targetport'] + "\n" if xml_scan.has_attribute? "targetport"
        node_text += "Banner = " + xml_scan['targetbanner'] + "\n" if xml_scan.has_attribute? "targetbanner"
        node_text += "Starttime = " + xml_scan['starttime'] + "\n" if xml_scan.has_attribute? "starttime"
        node_text += "Site Name = " + xml_scan['sitename'] + "\n" if xml_scan.has_attribute? "sitename"
        node_text += "Site IP = " + xml_scan['siteip'] + "\n" if xml_scan.has_attribute? "siteip"
        node_text += "Host Header = " + xml_scan['hostheader'] + "\n" if xml_scan.has_attribute? "hostheader"
        node_text += "Errors = " + xml_scan['errors'] + "\n" if xml_scan.has_attribute? "errors"
        node_text += "Total Checks = " + xml_scan['checks'] + "\n" if xml_scan.has_attribute? "checks"

        content_service.create_note(
          text: "#[Title]#\nNikto upload: #{file_name}\n\n#{node_text}",
          node: host_node)

        # Check for SSL cert tag and add that data in as well
        unless xml_scan.at_xpath("ssl").nil?
          ssl_details = xml_scan.at_xpath("ssl")
          node_text = "#[Details]#\n"
          node_text += "Ciphers = " + ssl_details['ciphers'] + "\n" if ssl_details.has_attribute? "ciphers"
          node_text += "Issuers = " + ssl_details['issuers'] + "\n" if ssl_details.has_attribute? "issuers"
          node_text += "Info = " + ssl_details['info'] + "\n" if ssl_details.has_attribute? "info"

          content_service.create_note(
            text: "#[Title]#\nSSL Cert Information\n\n#{node_text}",
            node: host_node)
        end

        xml_scan.xpath("item").each do |xml_item|
          item_label = xml_item.has_attribute?("id") ? xml_item["id"] : "Unknown"
          item_node = content_service.create_node(
          label: item_label,
          type: :default,
          parent: host_node)

          item_text = template_service.process_template(template: 'item', data: xml_item)
          content_service.create_note(
            text: item_text,
            node: item_node)
        end
      end

      logger.info("All Done!")
    end
  end
end

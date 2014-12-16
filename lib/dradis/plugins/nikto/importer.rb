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

      doc.xpath('/nikto/niktoscan/scandetails').each do |scan_details|
        if scan_details.has_attribute? "sitename"
          host_label = scan_details['sitename']
        else
          host_label = scan_details['siteip']
        end

        # The rand is good for debugging as it means each node is fairly unique
        # host_label = host_label + " - " + Configuration.parent_node + rand(99).to_s

        logger.info{ 'Adding ' + host_label }
        # create the parent node early so we can use it to provide feedback on errors
        affected_host = content_service.create_node(label: host_label, type: :host)

        node_text = "#[Details]#\n"
        node_text += "IP = " + scan_details['targetip'] + "\n" if scan_details.has_attribute? "targetip"
        node_text += "Hostname = " + scan_details['targethostname'] + "\n" if scan_details.has_attribute? "targethostname"
        node_text += "Port = " + scan_details['targetport'] + "\n" if scan_details.has_attribute? "targetport"
        node_text += "Banner = " + scan_details['targetbanner'] + "\n" if scan_details.has_attribute? "targetbanner"
        node_text += "Starttime = " + scan_details['starttime'] + "\n" if scan_details.has_attribute? "starttime"
        node_text += "Site Name = " + scan_details['sitename'] + "\n" if scan_details.has_attribute? "sitename"
        node_text += "Site IP = " + scan_details['siteip'] + "\n" if scan_details.has_attribute? "siteip"
        node_text += "Host Header = " + scan_details['hostheader'] + "\n" if scan_details.has_attribute? "hostheader"
        node_text += "Errors = " + scan_details['errors'] + "\n" if scan_details.has_attribute? "errors"
        node_text += "Total Checks = " + scan_details['checks'] + "\n" if scan_details.has_attribute? "checks"

        content_service.create_note(
          text: "#[Title]#\nNikto upload: #{file_name}\n\n#{node_text}",
          node: affected_host)

        # Check for SSL cert tag and add that data in as well
        unless scan_details.at_xpath("ssl").nil?
          ssl_details = scan_details.at_xpath("ssl")
          node_text = "#[Details]#\n"
          node_text += "Ciphers = " + ssl_details['ciphers'] + "\n" if ssl_details.has_attribute? "ciphers"
          node_text += "Issuers = " + ssl_details['issuers'] + "\n" if ssl_details.has_attribute? "issuers"
          node_text += "Info = " + ssl_details['info'] + "\n" if ssl_details.has_attribute? "info"

          content_service.create_note(
            text: "#[Title]#\nSSL Cert Information\n\n#{node_text}",
            node: affected_host)
        end

        scan_details.xpath("item").each do |item|
          item_text  = "#[Title]#\n"
          item_text += "Finding\n\n"
          item_text += "#[Details]#\n"

          item_title = item.has_attribute?("id") ? item["id"] : "Unknown"
          if item.has_attribute? 'osvdbid'
            if item.has_attribute? 'osvdblink'
              item_text += 'OSVDB = "' + item['osvdbid'] + '":' + item['osvdblink'] + "\n"
            else
              item_text += 'OSVDB = ' + item['osvdbid'] + "\n"
            end
          end

          item_text += "Request Method = " + item['method'] + "\n"  if item.has_attribute? 'method'
          item_text += "Description = " + item.at_xpath("description").text + "\n"  unless item.at_xpath("description").nil?
          item_text += 'Link = "' + item.at_xpath("namelink").text + '":' + item.at_xpath("namelink").text + "\n"  unless item.at_xpath("namelink").nil?
          item_text += 'IP Based Link = "' + item.at_xpath("iplink").text + '":' + item.at_xpath("iplink").text + "\n"  unless item.at_xpath("iplink").nil?

          alert_node = content_service.create_node(
          label: item_title,
          type: :default,
          parent: affected_host)

          content_service.create_note(
            text: item_text,
            node: alert_node)
        end
      end

      logger.info("All Done!")
    end
  end
end

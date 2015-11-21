module Sufia
  module SolrDocument
    module Export
      # MIME: 'application/x-endnote-refer'
      def export_as_endnote
        end_note_format = {
          '%T' => [:title],
          # '%Q' => [:title, ->(x) { x.drop(1) }], # subtitles
          '%A' => [:creator],
          '%C' => [:publication_place],
          '%D' => [:date_created],
          '%8' => [:date_uploaded],
          '%E' => [:contributor],
          '%I' => [:publisher],
          '%J' => [:series_title],
          '%@' => [:isbn],
          '%U' => [:related_url],
          '%7' => [:edition_statement],
          '%R' => [:persistent_url],
          '%X' => [:description],
          '%G' => [:language],
          '%[' => [:date_modified],
          '%9' => [:resource_type],
          '%~' => I18n.t('sufia.product_name'),
          '%W' => I18n.t('sufia.institution_name')
        }
        text = []
        text << "%0 #{human_readable_type}"
        end_note_format.each do |endnote_key, mapping|
          if mapping.is_a? String
            values = [mapping]
          else
            values = send(mapping[0]) if self.respond_to? mapping[0]
            values = mapping[1].call(values) if mapping.length == 2
            values = Array(values)
          end
          next if values.blank? || values.first.nil?
          spaced_values = values.join("; ")
          text << "#{endnote_key} #{spaced_values}"
        end
        text.join("\n")
      end

      def persistent_url
        "#{Sufia.config.persistent_hostpath}#{id}"
      end
    end
  end
end

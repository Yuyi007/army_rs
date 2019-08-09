
def numeric?(value)
  true if Float(value)
rescue
  false
end

excel_document(xml) do
  xml.Worksheet 'ss:Name' => @file_name do
    xml.Table do
      #header
      xml.Row do
        @header.each do |h|
          xml.Cell { xml.Data h["text"], 'ss:Type' => 'String' }
        end
      end
      #rows
      @data.each do |d|
        xml.Row do
          @header.each do |h|
            value = d[h["dataIndex"]]
            fmt = 'String'
            fmt = 'Number' if numeric? value
            xml.Cell { xml.Data value, 'ss:Type' => fmt }
          end
        end
      end
    end
  end
end
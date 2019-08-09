module ApplicationHelper
  def excel_document(xml, &block)
    xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8" 
    xml.Workbook({
      'xmlns'      => "urn:schemas-microsoft-com:office:spreadsheet", 
      'xmlns:o'    => "urn:schemas-microsoft-com:office:office",
      'xmlns:x'    => "urn:schemas-microsoft-com:office:excel",    
      'xmlns:html' => "http://www.w3.org/TR/REC-html40",
      'xmlns:ss'   => "urn:schemas-microsoft-com:office:spreadsheet" 
    }) do

      xml.Styles do
        xml.Style 'ss:ID' => 'Default', 'ss:Name' => 'Normal' do
          xml.Alignment 'ss:Vertical' => 'Bottom'
          xml.Borders
          xml.Font 'ss:FontName' => 'Arial'
          xml.Interior
          xml.NumberFormat
          xml.Protection
        end
      end

      yield block
    end
  end
end

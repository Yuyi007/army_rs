class SaveLabelInfo < Handler
  def self.process(session, msg, model)
    instance  = model.instance
    mylabel     = msg['label']
    instance.label.clear
    if !mylabel.empty? 
      mylabel.each do |i|
        instance.label << i
      end
    end       
    res = {
      'success' => true,
      'labels' => instance.label
    }
  end
end
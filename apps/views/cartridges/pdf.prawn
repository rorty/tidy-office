
pdf.font_families.update(
  "Consolas" => {
    :bold => "consolab.ttf",
    :italic => "consolai.ttf",
    :normal  => "consola.ttf" })
pdf.font("Consolas", :style => :italic)
@devices.each_with_index do |item, index| 
    barcode = Barby::Code128A.new(item[2])
    outputter = Barby::PrawnOutputter.new(barcode)        
    pdf.bounding_box([50.mm, pdf.bounds.top - 10.mm * index], :width => 90.mm, :height => 10.mm) do
        pdf.bounding_box([0, pdf.bounds.top], :width => 20.mm, :height => pdf.bounds.top) do 
            pdf.svg IO.read("logo2.svg"), :position => :center, :vposition => :top, :height => 11, :width => 18.mm
        end
        pdf.bounding_box([20.mm, pdf.bounds.top], :width => 35.mm, :height => pdf.bounds.top) do
            pdf.move_down 3
            pdf.text_box item[0], :at => [0, pdf.cursor], :align => :center
            pdf.move_down 13
            pdf.text_box item[1], :at => [0, pdf.cursor], :align => :center#, :size => 8
        end
        pdf.bounding_box([55.mm, pdf.bounds.top], :width => 35.mm, :height => pdf.bounds.top) do
            pdf.move_down 3
            outputter.annotate_pdf pdf, height: 12, :x => (pdf.bounds.width / 2) - (outputter.width / 2), :y => pdf.cursor - 12, :xdim => 1
            pdf.move_down 13
            pdf.text_box item[2], :at => [0, pdf.cursor], :align => :center
        end
        pdf.transparent(0.05) {  pdf.stroke_bounds }         
    end
end 
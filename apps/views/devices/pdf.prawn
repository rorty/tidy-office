pdf.font_families.update(
  "Consolas" => {
    :bold => "consolab.ttf",
    :italic => "consolai.ttf",
    :normal  => "consola.ttf" })
pdf.font("Consolas", :style => :italic)
@devices.each_with_index do |item, index| 
    barcode = Barby::Code128A.new(item[2])
    outputter = Barby::PrawnOutputter.new(barcode)
    pdf.bounding_box([45.mm + (index % 2) * 50.mm, pdf.bounds.top - 30.mm * (index / 2)], :width => 50.mm, :height => 30.mm) do
        pdf.bounding_box([3, pdf.bounds.top], :width => 3.mm,:height => pdf.bounds.top) do
          pdf.svg IO.read("logo1.svg"), :position => :left
        end
        pdf.bounding_box([5.mm, pdf.bounds.top], width: 45.mm, height: 20.mm) do
            pdf.text_box "#{item[0]}\n#{item[1]}", :at => [0, pdf.cursor], :align => :center, :valign => :center
        end
        pdf.bounding_box([5.mm, pdf.bounds.top - 20.mm], :width => 45.mm, :height => pdf.bounds.top) do
            pdf.move_down 3
            outputter.annotate_pdf pdf, height: 15, :x => (pdf.bounds.width / 2) - (outputter.width / 2), :y => pdf.cursor - 12, :xdim => 1
            pdf.move_down 13
            pdf.text_box item[2], :at => [0, pdf.cursor], :align => :center
        end
        pdf.transparent(0.05) {  pdf.stroke_bounds }         
    end
end 
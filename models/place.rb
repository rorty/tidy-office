class Place < Sequel::Model
  plugin :rcte_tree, order: :name
  one_to_many :devices, conditions: { status: "installed" }, order: Sequel.desc(:created_at)
  one_to_many :event, conditions: {
  }, limit: 10, order: Sequel.desc(:id)

  dataset_module do 
    order :by_name, :name
    def text_search(query) 
      query = query.gsub(/[^\w\s\-\.'\p{L}]/u, '').strip
      where(Sequel.lit('upper([NAME]) LIKE upper(:s)', s: "%#{query}%"))
    end
    
    def asci_tree
      prepare.roots.inject([]) do |all, root|
        all + render_tree(root, root.children).map do |prefix, place|
          { prefix: prefix,id: place.id, name: place.name, disabled: place.disabled }
        end  
      end  
    end

    def render_tree child, children
      lines = [["", child]]
      children.each_with_index do |child, index|
        child_lines = render_tree(child, child.children) 
        if index < children.size - 1
          child_lines.each_with_index do |(prefix, target), idx|
            lines << [ (idx == 0) ? "├─ " : "|  " << prefix, target ] 
          end
        else
          child_lines.each_with_index do |(prefix, target), idx|
            lines << [ (idx == 0) ? "└─ " : "   " << prefix, target ] 
          end
        end
      end
      lines
    end

    def arrange options = {}
      if (order = options.delete(:order))
        arrange_nodes order(order).where(options)
      else
        arrange_nodes where(options)
      end
    end

    def arrange_nodes(nodes)
      node_ids = Set.new(nodes.map(&:id))
      index = Hash.new { |h, k| h[k] = {} }

      nodes.each_with_object({}) do |node, arranged|
        children = index[node.id]
        index[node.parent_id][node] = children
        arranged[node] = children unless node_ids.include?(node.parent_id)
      end
    end

    def full_ancestors id
      Place.eager(:ancestors)[id].ancestors
    end

    def prepare
      eager(:descendants).where(disabled: false)
    end
  end

  def validate
    validates_presence :name
    errors.add(:parent_id, "уже определен корень #{model.name}") if !parent_id.blank? && id == parent_id
  end

  def title
    "#{name}"
  end
end
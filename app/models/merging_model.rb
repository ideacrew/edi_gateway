module MergingModel

  def merge_with_overwrite(target, *attrs)
    assignment_pairs = attrs.map { |a| ["#{a}=".to_sym, a.to_sym] }
    assignment_pairs.each do |pair|
      update_val = target.public_send(pair.last)
      self.public_send(pair.first, update_val)
    end
  end

  def merge_without_blanking(target, *attrs)
    assignment_pairs = attrs.map { |a| ["#{a}=".to_sym, a.to_sym] }
    assignment_pairs.each do |pair|
      update_val = target.public_send(pair.last)
      unless update_val.blank?
        self.public_send(pair.first, update_val)
      end
    end
  end

end

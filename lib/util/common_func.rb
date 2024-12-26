module Common
  def parse_params(ps)
    if ps.is_a?(String)
      h = {}
      ar = ps.split(',')
      ar.each do |e|
        ar_h = e.split(':')
        ar_h[1] = nil if ar_h[1] == 'null'
        ar_h[1] = ar_h[1].to_objid if ar_h[0] == '_id'
        h = h.merge(Hash[*ar_h])
      end
      [h, {}]
    else
      ps
    end
  end

  def gen_id
    SecureRandom.base64(8).gsub("/", "_").gsub(/[=+$]/, "")
  end

  def kr_parse_objtree(tree)
    tree.gsub(/\/\/\[(.+?)\]\/\//, "\\1")
  end

  def kr_get_objtree(tree)
    match = tree.match(/\/\/\[(.+?)\]\/\//)
    match.nil? ? nil : JSON.parse(match[1], { symbolize_names: true })
  end
end
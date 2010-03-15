module BookHelper
  

  def pre_escape(revision)
    revision.collect do |ln| 
      if !ln.is_a?(Array)
        ln = h(ln.to_s).gsub(/$/,"<br/>")
      else
        ln[1] = ln[1].gsub("  ","&nbsp;").gsub("\n","<br/>")
        ln = [ln[0], ln[1]]
      end
    end
  end
  def output_diff_pretty(revision)
    revision.collect do |ln| 
      if !ln.is_a?(Array)
        ln = "#{ln}\n"
      else
        case ln[0]
        when 1: ["<div class='add'>#{ln[1]}</div>\n"]
        when -1: ["<div class='rem'>#{ln[1]}</div>\n"]
        else; "#{ln}\n";
        end
      end
    end  
  end
end

module BookHelper
  

  def pre_escape(revision)
    revision.collect do |ln| 
      if !ln.is_a?(Array)
        ln = h(ln.to_s).gsub(/"\n\n"/,"<br/><br/") 
      else
       ln[1] =  h(ln[1]).gsub(" ","&nbsp;").gsub("\n\n","<br/><br/>")
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
        when 1: ["<span class='add'>#{ln[1]}</span>"]
        when -1: ["<span class='rem'>#{ln[1]}</span>"]
        else; "#{ln}";
        end
      end
    end  
  end
end

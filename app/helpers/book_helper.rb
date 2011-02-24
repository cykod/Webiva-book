module BookHelper
  def pre_escape(revision)
    revision.collect do |ln| 
      if !ln.is_a?(Array)
        ln = h(ln.to_s).gsub("  "," &nbsp;").gsub("\n\n","<br/>").gsub("&nbsp;\n","&nbsp;")
      else
       ln[1] =  h(ln[1]).gsub("  "," &nbsp;").gsub("\n\n","<br/>").gsub("&nbsp;\n","&nbsp;")
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
        when 1: ["<span class='add'>#{ln[1]}</span>\n"]
        when -1: ["<span class='rem'>#{ln[1]}</span>\n"]
        else; "#{ln}";
        end
      end
    end  
  end

  def edit_url(options, book, page=nil)
    return '' unless options.edit_page_url
    url = options.edit_page_url
    url += "/#{book.id}" if options.book_id.blank? # using page connections
    if page
      if page.is_a?(String)
        url += "/#{page}"
      else
        url += page.path
      end
    end
    url
  end

  def content_url(options, book, page)
    return '' unless options.root_page_url
    url = options.root_page_url.to_s
    url += "/#{book.id}" if options.book_id.blank? # using page connections
    url += page.path.to_s
    url
  end
end

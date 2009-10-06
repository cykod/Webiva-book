

class Book::PageRenderer < ParagraphRenderer

  features '/book/page_feature'
  features '/editor/menu_feature'

  paragraph :chapters
  paragraph :content

  def chapters

    # Get book from options
    @options = paragraph_options(:chapters)

    @book = find_book 
    return render_paragraph :text => '' unless @book

    page_conn_type,page_url = page_connection(:flat_chapter)
    
    @chapters = @book.nested_pages

    @menu, selected = build_chapter_data(@chapters,@options.levels-1,@options.root_page_url.to_s + '/',page_url.to_s)

    render_paragraph :text => menu_feature()
  end

  def build_chapter_data(chapters,level,path = '',current_path='')
     chapter_selected = nil
     chaps = chapters.map do |chapter|
      if chapter.published?
        url =  ( path + chapter.url.to_s)
        menu, selected = (level > 0) ? build_chapter_data(chapter.child_cache,level-1,path,current_path) : [ nil, nil ]
        if !selected
          selected = chapter.url.to_s != '' && chapter.url.to_s == current_path
        end
        chapter_selected ||= selected
        {
          :title => chapter.name,
          :link => url,
          :menu => menu,
          :selected => selected
        }
      else
        nil
      end
    end.compact
    [ chaps, chapter_selected ]
  end

  
  def content

    @options = paragraph_options(:content)

    @book = find_book

    return render_paragraph :text => '' unless @book

    if @book.flat_url?
      page_conn_type,page_url = page_connection(:flat_chapter)

      if @options.show_first_page && page_url.blank?
        @page = @book.root_node.children[0]
      else
        @page = @book.book_pages.find_by_url_and_published(page_url,true,:conditions => 'parent_id IS NOT NULL')
      end
    else
      raise 'Unsupported...'
    end

    if @page
      set_title(@page.name)
    else
      set_title('Invalid Page')
    end
    
    @url = site_node.node_path
    
    render_paragraph :text => book_page_content_feature()
  end

  protected

  def find_book
    book_id = @options.book_id
    if book_id.to_i == 0
      conn_type,book_id = page_connection(:book)
    end

    book = BookBook.find_by_id(book_id)

    # Get a dummy book for the editor if needed
    book = BookBook.find(:first) if !book && editor?

    book

  end

end



class Book::PageRenderer < ParagraphRenderer

  features '/book/page_feature'
  features '/editor/menu_feature'

  
  paragraph :chapters
  paragraph :content
  paragraph :wiki_editor

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
      unless params[:ref].blank? 
        @page = @book.book_pages.find_by_reference_and_published(params[:ref], true)
      end 
      unless @page 
        page_conn_type,page_url = page_connection(:flat_chapter)

        if @options.show_first_page && page_url.blank?
          @page = @book.first_page
        else
          @page = @book.book_pages.find_by_url_and_published(page_url,true,:conditions => 'parent_id IS NOT NULL')
        end
      end
    else
      raise 'Unsupported...'
    end

    if @page
      set_title(@page.name)
      set_page_connection(:content_id, ['BookPage',@page.id])
      set_content_node(@page)
    else
      set_title('Invalid Page')
    end
    
    @url = site_node.node_path

   render_paragraph :text => book_page_content_feature()
  end

  def can_edit
    @options = paragraph_options(:content)

    edit_url if @options.enable_wiki
  end
  def edit_url
#    @options = wiki_page_url \ book_url 
     url_for(:path => @page.url)
    
  end
  def wiki_editor
    @options = paragraph_options(:wiki_editor)
    @book = find_book

    return render_paragraph :text => '' unless @book
     if @book.flat_url?
      unless params[:ref].blank? 
        @page = @book.book_pages.find_by_reference_and_published(params[:ref], true)
      end 
      unless @page 
        page_conn_type,page_url = page_connection(:flat_chapter)

        if @options.show_first_page && page_url.blank?
          @page = @book.first_page
        else
          @page = @book.book_pages.find_by_url_and_published(page_url,true,:conditions => 'parent_id IS NOT NULL')
        end
      end
    else
      raise 'Unsupported...'
    end
    
    if request.post? 
      
      # need to accept the edit data and redirect the user back to the book page

      save_page
      
    end

    
    if @page
      set_title(@page.name)
      set_page_connection(:content_id, ['BookPage',@page.id])
      set_content_node(@page)
    else
      set_title('Invalid Page')
      # set_content_node(@page.edit)

    end
    
    @url = site_node.node_path
    
    render_paragraph :text => book_page_wiki_editor_feature()
  end

  def save_page

    @version = BookPageVersion.new()
    @book =  BookBook.find(params[:path][0])
    @page_versions = params[:page_versions]

    #raise params.inspect
   # @page_versions.save_content(myself)

  end

  protected

  def find_book
    book_id = @options.book_id
    if book_id.to_i == 0
      conn_type,book_id = page_connection(:book)
    end

    @book_url = "\#{id}" || ""
    book = BookBook.find_by_id(book_id)

    # Get a dummy book for the editor if needed
    book = BookBook.find(:first) if !book && editor?

    book

  end

end

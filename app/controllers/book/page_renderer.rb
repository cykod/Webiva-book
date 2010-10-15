

class Book::PageRenderer < ParagraphRenderer

  features '/book/page_feature'
  features '/editor/menu_feature'

  paragraph :chapters
  paragraph :content
  paragraph :wiki_editor

  attr_accessor :editor, :body, :edit_type, :version_status, :remote_ip
  
  def chapters
    @options = paragraph_options(:chapters)
    @book = self.find_book
    return render_paragraph :text => 'No book found' unless @book

    @page = self.find_page

    @chapters = @book.nested_pages

    root_url = @options.root_page_url.to_s + '/'
    page_url = @page ? @page.url : ''
    @menu, selected = build_chapter_data(@chapters, @options.levels-1, root_url, page_url)

    render_paragraph :text => menu_feature()
  end

  def content
    @options = paragraph_options(:content)
    @book = self.find_book
    return render_paragraph :text => 'No book found' unless @book
    return render_paragraph :text => 'Unsupported book url scheme...' if @book.nested_url?

    @page = self.find_page
    return render_paragraph :text => 'No page found' if @page.nil? && editor?
    raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @page

    @book_save = flash[:book_save]

    set_title(@page.name)
    set_title(@page.name, "page")
    set_content_node(@page.content_node.id) if @page.content_node

    @edit_url = edit_url

    render_paragraph :text => book_page_content_feature()
  end

  def wiki_editor
    @options = paragraph_options(:wiki_editor)
    @book = self.find_book
    return render_paragraph :text => 'No book found' unless @book
    return render_paragraph :text => 'Unsupported book url scheme...' if @book.nested_url?

    @page = self.find_page
    @page ||= @book.book_page.new if @options.allow_create
    return render_paragraph :text => 'No page found' if @page.nil? && editor?
    raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @page

    if request.post? && params[:commit]
      if save_page
      end
    end

    set_title(@page.name)
    set_title(@page.name, "page")
    set_content_node(@page.content_node.id) if @page.content_node
    
    render_paragraph :text => book_page_wiki_editor_feature()
  end

  protected

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

  def edit_url
    if @options.enable_wiki && @options.edit_page_url
      "#{@options.edit_page_url}/#{@page.url}"
    end
  end
  
  def save_page
    if params[:commit] && @page
      @newpage = @page.new_record?
      
      if @options.allow_auto_version

        @page.body = params[:page_versions][:body]
        @page.edit_type = "wiki_auto_publish"
        @page.editor = myself.id
        @page.v_status = "accepted wiki"
        @page.remote_ip = @ipaddress
        if @page.book_page_versions.latest_revision == []
          @page.prev_version = nil
        else 
          @page.prev_version = @page.book_page_versions.latest_revision[0].id
        end
        @page.save
        @page.move_to_child_of(@book.root_node) if @book.book_type == 'chapter' && @newpage

        flash[:book_save] = "Page Saved".t

        redirect_paragraph "#{@options.content_page_url}/#{@page.url}"
        return true
      elsif @page.new_record? 

        
        @page.body = params[:page_versions][:body]
        @page.edit_type = "wiki"
        
        @page.editor = params[:page_versions][:editor]||myself.id
        @page.v_status = "submitted"
        @page.remote_ip = @ipaddress
        @page.prev_version = nil
        @page.save
        @page.move_to_child_of(@book.root_node) if @book.book_type == 'chapter' && @newpage

        flash[:book_save] = "Page Created and Submitted for review".t

        redirect_paragraph "#{@options.content_page_url}"
        return true
      else 
        @prev_version = @page.book_page_versions.latest_revision
        
        @page.save_version(myself.id,params[:page_versions][:body],'wiki','submitted',@ipaddress,@prev_version[0].id)
        
        flash[:book_save] = "Your edits have been submitted for review.".t

        redirect_paragraph  "#{@options.content_page_url}/#{@page.url}"
        return true
      end
      return false
    end
  end

  def find_book
    # using page connections
    if @options.book_id.blank?
      if editor?
        @book = BookBook.first
      else
        conn_type, book_id = page_connection :book
        @book = BookBook.find_by_id book_id
      end
    else
      @book = BookBook.find_by_id @options.book_id
    end

    unless editor?
      raise SiteNodeEngine::MissingPageException.new(site_node, language) if @book.nil? || @book.nested_url?
    end

    @book
  end

  def find_page
    return unless @book
    return @page = @book.first_page if editor?

    @page = @book.book_pages.find_by_reference(params[:ref]) if params[:ref]

    if @page.nil?
      conn_type, conn_id = page_connection(:flat_chapter)

      if conn_id.blank?
        @page = @book.first_page if @options.show_first_page
      elsif @book.flat_url?
        @page = @book.book_pages.find_by_url conn_id
      elsif @book.id_url?
        @page = @book.book_pages.find_by_id conn_id
      end
    end

    @page = nil if @page && ! @page.published?
    @page
  end
end

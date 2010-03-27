

class Book::PageRenderer < ParagraphRenderer

  features '/book/page_feature'
  features '/editor/menu_feature'

  
  paragraph :chapters
  paragraph :content
  paragraph :wiki_editor

  attr_accessor :editor, :body, :edit_type, :version_status, :remote_ip
 
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

    if editor?
        @page = @book.first_page
    elsif @book.flat_url?
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

        if !@page && !page_url.blank?
          @create_page_url = page_url
        end
      end
    else
      raise 'Unsupported...'
    end

    @book_save = flash[:book_save]

    if @page
      set_title(@page.name)
      set_title(@page.name,"page")
      set_page_connection(:content_id, ['BookPage',@page.id])
      set_content_node(@page)
      
    else
      set_title('Invalid Page')
    end
    
    @url = site_node.node_path

    @edit_url = edit_url

   render_paragraph :text => book_page_content_feature()
  end

  def can_edit
    @options = paragraph_options(:content)
    edit_url if @options.enable_wiki
  end
  def edit_url

    if @options.enable_wiki && @page
      "#{@options.edit_page_url}/#{@page.url}"
    elsif @options.enable_wiki && @create_page_url
      "#{@options.edit_page_url}/#{@create_page_url}"
    else
      nil
    end


  end
  
  def add_page
    @book.book_pages.build(:title => title_)
     return 'this-page'
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

        if !@page && @options.allow_create && !page_url.blank?
          @page = @book.book_pages.build(:name => page_url.titleize)
        end
      end
    else
      raise 'Unsupported...'
    end

    @ipaddress = request.remote_ip
   

    if request.post? && params[:commit]    
      return if save_page
    elsif request.post? && params[:reset]
    @page.reload
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
    if params[:commit] && @page
      @newpage = @page.new_record?
      
      if @options.allow_auto_version

        @page.body = params[:page_versions][:body]
        @page.edit_type = "wiki_auto_publish"
        @page.editor = myself.id
        @page.v_status = "accepted wiki"
        @page.remote_ip = @ipaddress
        @page.prev_version = nil
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

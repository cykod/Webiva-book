

class Book::PageRenderer < ParagraphRenderer

  include BookHelper

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
    return render_paragraph :text => 'Unsupported book url scheme...' if @book.nested_url?

    @page = self.find_page

    @chapters = @book.nested_pages

    @menu, selected = build_chapter_data(@chapters, @options.levels)

    render_paragraph :text => menu_feature()
  end

  def content
    @options = paragraph_options(:content)
    @options.root_page_id = site_node.id

    @book = self.find_book
    return render_paragraph :text => 'No book found' unless @book
    return render_paragraph :text => 'Unsupported book url scheme...' if @book.nested_url?

    @page = self.find_page
    unless @options.enable_wiki
      return render_paragraph :text => 'No page found' if @page.nil? && editor?
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @page && @page.published?
    end

    @notice = flash[:book_save]

    if @page
      set_title(@page.name)
      set_title(@page.name, "page")
      set_content_node(@page.content_node.id) if @page.content_node
    end

    render_paragraph :text => book_page_content_feature()
  end

  def wiki_editor
    @options = paragraph_options(:wiki_editor)
    @book = self.find_book
    return render_paragraph :text => 'No book found' unless @book
    return render_paragraph :text => 'Unsupported book url scheme...' if @book.nested_url?

    @page = self.find_page
    @page ||= @book.book_pages.new(:url => @missing_page_url) if @options.allow_create
    return render_paragraph :text => 'No page found' if @page.nil? && editor?
    raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @page

    if request.post? && params[:commit] && params[:page]
      if save_page
        flash[:book_save] = @newpage ? "Page created and submitted for review".t : "Your edits have been submitted for review".t

        action = @newpage ? 'new_page' : 'update_page'
        action_path = "/book/#{action}"
        paragraph_action(myself.action(action_path, :target => @page, :identifier => @page.name))
        paragraph.run_triggered_actions(@page,action,myself)
        
        url = @page.published? ? content_url(@options, @book, @page) : @options.root_page_url

        return redirect_paragraph url
      end
    elsif @missing_page_url
      @page.name = @missing_page_url.gsub(/[_\-]/, ' ').titleize
    end

    if @page && @page.id
      set_title(@page.name)
      set_title(@page.name, "page")
      set_content_node(@page.content_node.id) if @page.content_node
    end

    render_paragraph :text => book_page_wiki_editor_feature()
  end

  protected

  def build_chapter_data(chapters, levels)
    chapter_selected = nil
    chaps = chapters.map do |chapter|
      if chapter.published? && levels > 0
        menu, selected = build_chapter_data(chapter.child_cache, levels-1)
        selected ||= @page && @page.id && chapter.id == @page.id
        chapter_selected ||= selected

        {
          :title => chapter.name,
          :link => content_url(@options, @book, chapter), # from BookHelper
          :menu => menu,
          :selected => selected
        }
      else
        nil
      end
    end.compact
    [ chaps, chapter_selected ]
  end

  def save_page
    @newpage = @page.id.nil?

    if @newpage || @options.allow_auto_version

      @page.name = params[:page][:name] if @newpage
      @page.body = params[:page][:body]
      @page.remote_ip = request.remote_ip
      @page.editor = myself.id
      @page.edit_type = @options.auto_save_version ? 'wiki_auto_publish' : 'wiki'
      @page.v_status = @options.auto_save_version ? 'accepted wiki' : 'submitted'
      @page.published = @options.auto_save_version ? true : false

      return false unless @page.save

      @page.move_to_child_of(@book.root_node) if @newpage && @book.chapter_book?
      return true
    end

    return @page.save_version(myself.id, params[:page][:body], 'wiki', 'submitted', request.remote_ip)
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

    conn_type, conn_id = page_connection(:flat_chapter)

    if conn_id.blank?
      @page = @book.book_pages.find_by_reference(params[:ref]) if params[:ref]
      @page ||= @book.first_page if @options.show_first_page
    elsif @book.flat_url?
      @page = @book.book_pages.find_by_url conn_id
      @missing_page_url = conn_id unless @page
    elsif @book.id_url?
      @page = @book.book_pages.find_by_id conn_id
    end

    @page = nil if @page && ! @page.published?
    @page
  end
end

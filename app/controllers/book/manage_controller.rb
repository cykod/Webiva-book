

class Book::ManageController < ModuleController

  component_info 'Book'
  
  cms_admin_paths 'content'

  helper :active_tree

  def book
    @book = BookBook.find_by_id(params[:path][0]) || BookBook.new

    cms_page_path ['Content'], @book.id ? [ "Configure %s",nil,@book.name ] : 'Create a book'
    cms_page_info [ ["Content",url_for(:controller => '/content') ], "Create a new Book"], "content"

    if request.post? && params[:book]
      if params[:commit]
        @new_book = @book.id ? false : true
        if @book.update_attributes(params[:book])
          redirect_to :action => 'edit', :path => @book.id
        end
      else
        if @book.id
          redirect_to :action => 'edit', :path => @book.id
        else
          redirect_to :controller => '/content'
        end
        return
      end
    end
    
  end

  def edit
    @book = BookBook.find(params[:path][0])

    @chapters = @book.nested_pages

    if @chapters.length == 0
      @page = @book.book_pages.create(:name => 'Default Page',:created_by_id => myself.id)
      @page.move_to_child_of(@book.root_node)
      @book.reload
      @chapters = @book.nested_pages
    end

    

    cms_page_path ['Content'], [ 'Edit %s',nil,@book.name ]

    require_js('scriptaculous-sortabletree/sortable_tree.js')
    
  end

  def update_tree
    @book = BookBook.find(params[:path][0])

    # return the page and the destination page
    active_tree_move(params[:chapter_tree]) do |page_id,move_page_id|
      [ @book.book_pages.find(page_id), move_page_id ?  @book.book_pages.find(move_page_id) : @book.root_node ]
    end
  
    render :nothing => true
  end

  def add_to_tree
    @book = BookBook.find(params[:path][0])

    @parent_page = @book.book_pages.find(params[:page_id])

    @page = @book.book_pages.create(:name => 'New Page')

    case params[:position]
    when 'top':
        @page.move_to_left_of(@parent_page)
    when 'bottom':
        @page.move_to_right_of(@parent_page)
    else
      @page.move_to_child_of(@parent_page)
    end

    @book.reload
    @chapters = @book.nested_pages

  end

  def page
    @book = BookBook.find(params[:path][0])

    @page = @book.book_pages.find_by_id(params[:page_id]) || @book.book_pages.build(:created_by_id => myself.id)

    if request.post? && params[:page]
      @page.updated_by_id = myself.id
      if @page.save_content(myself,params[:page])
        @updated=true;
      end
    end

    render :partial => 'page'
  end

  def preview_page

    @book =  BookBook.find(params[:path][0])

    @page = @book.book_pages.find(params[:page_id])

    @page.attributes = params[:page]
    @page.pre_process_content_filter_body

    render :partial => 'preview_page'
  end

  def delete_page
    
    @book = BookBook.find(params[:path][0])

    @page = @book.book_pages.find(params[:page_id])
    @page.attributes = params[:page]

    if request.post? && params[:destroy] == 'yes'
      @page.destroy
    end
  end


  def search
     @book =  BookBook.find(params[:path][0])

     @pages = @book.book_pages.find(:all,:conditions => [ 'name LIKE ?',"%#{params[:search]}%" ],:order => 'name')
  end
  
  def delete
    @book =  BookBook.find(params[:path][0])
    cms_page_path ['Content'],['Delete %s',nil,@book.name ]

    if request.post? && params[:destroy] == 'yes'
      @book.destroy

      redirect_to :controller => '/content', :action => 'index'
    end
    
  end
  
  protected

  def active_tree_move(pages)
    
    params[:chapter_tree].each do |page_id,args|

      if !args[:left_id].blank?
        page, move_page = yield(page_id,args[:left_id])
        page.move_to_right_of(move_page)
      elsif args[:parent_id] != 'null' && !args[:parent_id].blank?
        page, move_page = yield(page_id,args[:parent_id])
        if(move_page.children.length > 0)
          page.move_to_left_of(move_page.children[0]) if move_page.children[0] != page
        else
          page.move_to_child_of(move_page)
        end
      else
        page, move_page = yield(page_id,nil)
        if(move_page.children.length > 0)
          page.move_to_left_of(move_page.children[0]) if move_page.children[0] != page
        else
          page.move_to_child_of(move_page)
        end
      end
    end
  end

end

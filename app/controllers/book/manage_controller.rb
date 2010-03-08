# Copyright (C) 2010 Cykod LLC.


class Book::ManageController < ModuleController

  component_info 'Book'
  
  cms_admin_paths 'content',  "Versions" =>  {  :action => 'index'}


  helper :active_tree

  active_table :version_table, BookPageVersion, 
  [:check,:id,:created_by_id,hdr(:string, :version_status, :label => 'Status'),
   hdr(:string,:version_type, :label => 'Type'),:created_at]
  
  def book
    if (params[:path][0] != nil) 

      @book = BookBook.find_by_id(params[:path][0]) 
    else 
      @book = BookBook.new(params[:book] || { :add_to_site => true })
    end
    cms_page_path ['Content'], @book.id ? [ "Configure %s",nil,@book.name ] : 'Create a book'

    if request.post? && params[:book]
      if params[:commit]
        @new_book = @book.id ? false : true
        if @new_book 
          @book.book_type = params[:book][:book_type]
          @book.url_scheme = params[:book][:url_scheme]
          if(@book.save)
            if @book.add_to_site
              redirect_to :controller => '/book/wizard', :book_id => @book.id
              return
            elsif  @book.add_to_site.blank?
              redirect_to :controller => '/book/manage', :path => @book.id
              return 
            end
          end
        end
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

    if params[:path][1]
      @page = @book.book_pages.find_by_id(params[:path][1])
    end

    @chapters = @book.nested_pages
    
    if @chapters.length == 0 && @book.book_type == 'chapter'
      @page = @book.book_pages.create(:name => 'Default Page',:created_by_id => myself.id)
      @page.move_to_child_of(@book.root_node)
      @book.reload
      @chapters = @book.nested_pages
    end
    
    cms_page_path ['Content'], [ 'Edit %s',nil,@book.name ]

    require_js('scriptaculous-sortabletree/sortable_tree.js')
    

  end
  
  # def create_pdf
  #   @book = BookBook.find(params[:path][0])
  
  #   ## later

  # end
  
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

    # @page = params[:page_id] ? @book.book_pages.find(params[:page_id]) : @book.book_pages.build(:created_by_id => myself.id)
    display_version_table false

    render :partial => 'page'

  end

  def save_page
    @book =  BookBook.find(params[:path][0])
    
    @page = @book.book_pages.find_by_id(params[:page_id]) || @book.book_pages.build(:created_by_id => myself.id)
    @page.updated_by_id = myself.id
    @new_page = true unless @page.id
    
    if @page.save_content(myself,params[:page].merge(:editor => myself, :v_status => params[:v_type],:remote_ip => request.remote_ip))
      @updated=true;
      @chapters = @book.nested_pages
    end
    
    if !params[:draft_id].blank?    
      @version = @page.book_page_versions.find_by_id(params[:draft_id])  
      @version.delete
    end

    @save_error = params[:save_error]
  end
  
  
  def save_draft
    @book = BookBook.find(params[:path][0])
    
    @page = @book.book_pages.find(params[:page_id])
    if !params[:version_id].blank?
      @version = @page.book_page_versions.find_by_id(params[:version_id])  
      @version.update_attributes(:body => params[:page][:body]) if @version
    else
      @version = @page.save_version(myself, params[:page][:body], 'page', 'draft', @ipaddress)      
    end
  end 
  ############# export
  
  def export
    @book ||= BookBook.find(params[:path][0])
    cms_page_path ['Content'], [ 'Export Pages in %s',nil,@book.name ]
    @export_options =  [[ 'CSV - Comma Separated Values', 'csv' ]
                       ]   
    #    @export = DefaultsHashObject.new(:export_download => 'all', :export_format => 'csv')
  end
  def generate_export
    @book = BookBook.find(params[:path][0])
    worker_key = @book.run_worker(:export_book,
                                  :export_download => params[:export][:download],
                                  :export_format => params[:export][:export_format]
                                  )
    
    
    session[:book_download_worker_key] = worker_key
    
    render :nothing => true
    
  end
  def status   
    if(session[:book_download_worker_key]) 
      results =  Workling.return.get(session[:book_download_worker_key])
      
      @completed = results[:completed] if results
    end
  end


  def download_file
    @book =  BookBook.find(params[:path][0])
    if(session[:book_download_worker_key]) 
      results = Workling.return.get(session[:book_download_worker_key])
      
      send_file(results[:filename],
                :stream => true,
                :type => "text/" + results[:type],
                :disposition => 'attachment',
                :filename => sprintf("%s_%d.%s",@book.name.humanize,Time.now.strftime("%Y_%m_%d"),results[:type])
                )
      
      session[:book_download_worker_key] = nil
    else
      render :nothing => true
    end
    
  end
  ############# export
  def search
    @book =  BookBook.find(params[:path][0])
    @pages = @book.book_pages.find(:all,:conditions => [ 'name LIKE ?',"%#{params[:search]}%" ],:order => 'name')

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
    @page.destroy if @page
    @deleted=true

    @chapters = @book.nested_pages
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
  
  def auto_save
    if params[:autosave]
      @page.book_pages.save_version
    end  
  end
  
  def display_version_table(display=true)
    @book ||= BookBook.find(params[:path][0])
    @page ||= @book.book_pages.find_by_id(params[:page_id])
    
    active_table_action('version') do |act,pids|
      case act
      when 'delete': BookPageVersion.destroy(pids)
      when 'reviewed': BookPageVersion.find(pids).each { |uv|  uv.update_attribute(:version_status, 'reviewed' ) }
      end 
    end  
    
    @tbl = version_table_generate( params,
                                   :order => 'created_at DESC',
                                   :conditions => ['book_page_id = ?',@page.id])

    render :partial => 'version_table' if display
    
  end
  
  def view_wiki_edits
    
    @wiki_body = BookPageVersion.find_by_id(params[:path])
    render :partial => 'view_edits'
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

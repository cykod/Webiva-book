# Copyright (C) 2010 Cykod LLC.


class Book::ManageController < ModuleController
  helper 'book'

  include BookHelper

  component_info 'Book'
  
  cms_admin_paths 'content'

  helper :active_tree

  # need to include 
  include ActiveTable::Controller
  active_table :version_table,
               BookPageVersion, 
               [ :check,
                 :id,
                 :created_by_id,
                 hdr(:string, :version_status, :label => 'Status'),
                 hdr(:string,:version_type, :label => 'Type'),
                 :created_at
               ]
  
  
  
  def book
    if params[:path][0]
      @book = BookBook.find params[:path][0].to_i
      cms_page_path ['Content'], "Configure %s" / @book.name
    else 
      @book = BookBook.new :add_to_site => true
      @book.created_by_id = myself.id
      cms_page_path ['Content'], 'Create a book'
    end

    if request.post? && params[:book]

      if params[:commit]
        unless @book.id
          @book.url_scheme = params[:book][:url_scheme]
          @book.book_type = params[:book][:book_type]
        end

        if @book.update_attributes(params[:book])
          if ! @book.add_to_site.blank?
            redirect_to BookWizard.wizard_url.merge(:book_id => @book.id, :version => SiteVersion.current.id)
          else
            redirect_to :action => 'edit', :path => @book.id
          end
        end
      elsif @book.id
        redirect_to :action => 'edit', :path => @book.id
      else
        redirect_to :controller => '/content'
      end
    end
  end

  def edit
    @book = BookBook.find(params[:path][0])
    @page = @book.book_pages.find_by_id(params[:path][1]) if params[:path][1]

    @chapters = @book.nested_pages
    
    if @chapters.length == 0 && @book.book_type == 'chapter'
      @page = @book.book_pages.create(:name => 'Default Page',:created_by_id => myself.id)
      @page.move_to_child_of(@book.root_node)
      @book.reload
      @chapters = @book.nested_pages
    end
    
    cms_page_path ['Content'], 'Edit %s' / @book.name

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

    @page = @book.book_pages.create(:name => 'New Page', :created_by_id => myself.id)

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

    @page = @book.book_pages.find_by_id(params[:page_id]) || @book.book_pages.new(:created_by_id => myself.id)

    display_version_table false

    render :partial => 'page'

  end

  def save_page
    @book =  BookBook.find(params[:path][0])
    @page = @book.book_pages.find_by_id(params[:page_id]) || @book.book_pages.build(:name => params[:page][:name])
    @page.updated_by_id = myself.id
    @new_page = true unless @page.id
    @page.name = params[:page][:name]

    @page.body = params[:page][:body]
    @page.editor = myself
    @page.edit_type = nil
    @page.v_status = "auto"
    @page.remote_ip = @ipaddress
    if @page.book_page_versions.latest_revision == []
         @page.prev_version = nil
    else 
          @page.prev_version = @page.book_page_versions.latest_revision[0].id
    end
    @page.save
    @updated=true;
    @chapters = @book.nested_pages
    
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
      @prev_version =  @page.book_page_versions.latest_revision || nil
      @version = @page.save_version(myself, params[:page][:body], 'page', 'draft', @ipaddress,@prev_version[0].id)      
    end
  end 
  ############# export
  
  def export
    @book ||= BookBook.find(params[:path][0])
    cms_page_path ['Content'], [ 'Export Pages in %s',nil,@book.name ]
    @export_options =  [[ 'CSV - Comma Separated Values', 'csv' ]]   
    @export = DefaultsHashObject.new(:export_download => 'all', :export_format => 'csv')
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

    @page = @book.book_pages.find_by_id(params[:page_id]) || @book.book_pages.build

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
  def delete
    @book =  BookBook.find(params[:path][0])
    cms_page_path ['Content'],['Delete %s',nil,@book.name ] 
    if request.post? && params[:destroy] == 'yes'
      @book.destroy

      redirect_to :controller => '/content', :action => 'index'
    end
    
  end
  def display_version_table(display=true)
    @book ||= BookBook.find(params[:path][0])
    @page ||= @book.book_pages.find_by_id(params[:page_id]) || @book.book_pages.build
    
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
    
    @book = BookBook.find(params[:path][0])
    @vers_body = BookPageVersion.find(params[:version_id]) 
    @orig_body = BookPageVersion.find_by_id(@vers_body.base_version_id) || @vers_body
    @page = @book.book_pages.find(@vers_body.book_page_id)

    @wiki_body = @page.page_diff(@vers_body.body,@orig_body)
    @escaped_body = pre_escape @wiki_body
    @diff_body = output_diff_pretty(@escaped_body)
    @review_button = false unless @vers_body.version_status == 'submitted'

    if  @vers_body.body == "1" && @wiki_body == nil
      @diff = ""
    end
    
    render :action => 'view_edits', :layout => "manage_window", :path => @book.id 
  end
 
  def review_wiki_edits
    
    @book = BookBook.find(params[:path][0])
    @version = @book.book_page_versions.find(params[:version_id])
    @version.update_attributes(:version_status => "reviewed", :updated_at => Time.now)
    
    render :nothing => true
  end
  def accept_wiki_edits
    @book = BookBook.find(params[:path][0])
    @version = @book.book_page_versions.find_by_id(params[:version_id])
 
    @page = @book.book_pages.find(@version.book_page_id)
    
    @page.edit_type = "admin editor"
    @page.editor = myself
    @page.body = @version.body
  #  @page.prev_version = 
    @page.v_status = "accepted wiki"
    @page.save
    
    @version.update_attributes(:updated_at => Time.now, :version_status => "reviewed")

    render :nothing => true

  end


  def add_subpages_form
    @book =  BookBook.find(params[:path][0])

    if params[:page_ids]
      @pages = @book.book_pages.find(params[:page_ids])
      render :partial => 'add_subpages_form'
      
    else 
      @new_pages = params[:new_page][:page_names]
      @new_pages.each do |subs|  
        @parent = @book.book_pages.find(subs[0])
        subs[1].split("\n").map(&:strip).reject(&:blank?).each do |sub|
          @new_page = @book.book_pages.create(:name => sub)
          
          @new_page.move_to_child_of(@parent)
         
        end    
      end
      @tbl = bulkview_table_generate( params,
                                 :conditions => ['book_book_id = ? and name != ?',@book.id,'Root'])
    end
  end
  def edit_meta_form 
    @book = BookBook.find(params[:path][0])
    
    if params[:update_page]
      @page = @book.book_pages.find(params[:update_page].delete(:id))
      @page.update_attributes(params[:update_page])
      
      @tbl = bulkview_table_generate( params,
                                      :conditions => ['book_book_id = ? and name != ?',@book.id,'Root'])    
    else 
      @page = @book.book_pages.find(params[:page_id])
      render :partial => 'edit_meta_form'
      
    end
    
  end

  active_table :bulkview_table,
               BookPage, 
               [:check,
                hdr(:boolean, :published),
                hdr(:order,:lft, :label => 'Parent'),
                :name,
                hdr(:string,:description,:label => 'Page Description'),
                :created_at
               ]
  
  def bulk_edit
    @book = BookBook.find(params[:path][0])

    cms_page_path ['Content'], 'Bulk Edit Pages in %s' / @book.name

    display_bulkview_table(display)
  end

  def display_bulkview_table(display=true)
    @book = BookBook.find(params[:path][0])
    
    active_table_action('bulkview') do |act,pids|
      case act
      when 'publish': BookPage.find(pids).each { |uv|  uv.update_attribute(:published, true ) }
      when 'unpublish': BookPage.find(pids).each { |uv|  uv.update_attribute(:published, false ) }
      when 'delete': BookPage.destroy(pids) 
      end 
    end  
    
    @tbl = bulkview_table_generate( params, :order => 'lft',:conditions => ['book_book_id = ? and name != ?',@book.id,'Root'])
    render :partial => 'bulkview_table' if display
    
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

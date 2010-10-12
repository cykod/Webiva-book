

class Book::PageImportController < ModuleController
  component_info 'Book'

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' }

  require 'csv'

  def index
    @book = BookBook.find(params[:path][0])
    cms_page_path ['Content', [@book.name, url_for(:controller => '/book/manage', :action => 'edit', :path => @book.id)]], 'Import Pages'

    if request.post? && params[:import]
      if params[:commit]
        @file = DomainFile.find_by_id params[:import][:file]
        if @file && @file.mime_type == 'text/csv'
          redirect_to :action => 'confirm_import', :path => [@book.id, @file.id]
        else
          @im_error = @file ? 'Invalid file type'.t : 'Missing file'.t
        end
      else
        redirect_to :controller => '/book/manage', :action => 'edit', :path => @book.id
      end
    end
  end
  
  def check_pages
    @import_pages = []
    @@fields = [:id,:name,:description,:published,:body,:parent_id]

    reader = CSV.open(@file.filename, "r", ",")
    reader.shift
    reader.each do |row|
      attr = {}
      @@fields.each_with_index { |field,idx| attr[field] = row[idx] }

      @page = @book.book_pages.find_by_id(attr[:id])
      unless @page
        @page_parent = @book.book_pages.find_by_id(attr[:parent_id])
        @page = @page_parent ? @book.book_pages.find_by_name_and_parent_id(attr[:name], @page_parent.id) : @book.book_pages.find_by_name(attr[:name])
      end

      if @page
        @import_pages.push([@page.name, "Updated"])
      else
        @import_pages.push([attr[:name], "New"])
      end
    end

    @import_pages
  end

  def confirm_import   
    @book = BookBook.find params[:path][0]
    @file = DomainFile.find params[:path][1]

    cms_page_path ['Content', [@book.name, url_for(:controller => '/book/manage', :action => 'edit', :path => @book.id)]], 'Import Confirmation'

    if request.post?
      if params[:commit]
        session[:book_import_worker_key] = @book.run_worker(:do_import, :domain_file_id => @file.id, :user_id => myself.id)
        redirect_to :action => 'import', :path => @book.id
      else
        redirect_to :controller => '/book/manage', :action => 'edit', :path => @book.id
      end
    else
      check_pages
    end
  end

  def import
    @book = BookBook.find params[:path][0]
    cms_page_path ['Content', [@book.name, url_for(:controller => '/book/manage', :action => 'edit', :path => @book.id)]], 'Import Status'

    status

    @back_button_url = url_for :action => 'confirm'

    @finished_onclick = "document.location='#{url_for(:controller => '/book/manage', :action => 'edit', :path => @book.id)}';"
    @hide_back = false
    @enable_next = false
  end

  def status
    @book = BookBook.find params[:path][0]

    if session[:book_import_worker_key]
      results = Workling.return.get(session[:book_import_worker_key]) || { }
      @initialized = results[:initialized]
      @completed = results[:processed]
      @entries = results[:entries].to_i
      @imported = results[:imported].to_i
      @entries = 1 if @entries == 0
      @percentage = (@imported.to_f / @entries.to_f * 100.0).to_i
      @errors = []
    else
      @invalid_worker = true 
    end
  end
end







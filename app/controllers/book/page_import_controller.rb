require 'csv'

class Book::PageImportController < ModuleController
  component_info 'Book'

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' }

  def index
    @book = BookBook.find(params[:path][0])
    book_page_path 'Import Pages'

    if request.post? && params[:import]
      if params[:commit]
        @file = DomainFile.find_by_id params[:import][:file]
        if @file && @file.mime_type == 'text/csv'
          redirect_to :action => 'confirm', :path => [@book.id, @file.id]
        else
          @im_error = @file ? 'Invalid file type'.t : 'Missing file'.t
        end
      else
        redirect_to :controller => '/book/manage', :action => 'edit', :path => @book.id
      end
    end
  end
  
  def confirm
    @book = BookBook.find params[:path][0]
    @file = DomainFile.find params[:path][1]
    book_page_path 'Import Confirmation'

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
    book_page_path 'Import Status'
    status
  end

  def status
    @book ||= BookBook.find params[:path][0]

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

  protected

  def book_page_path(name)
    cms_page_path ['Content', [@book.name, url_for(:controller => '/book/manage', :action => 'edit', :path => @book.id)]], name
  end

  def check_pages
    reader = CSV.open(@file.filename, "r", ",")
    reader.shift
    @import_pages = reader.collect do |row|
      page = BookPage.import_csv(@book, myself, row, :no_save => true)
      if page.is_a?(BookPage)
        [page.name, "Updated"]
      else
        [page[:name], "New"]
      end
    end
  end
end







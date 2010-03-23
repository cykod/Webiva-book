

class Book::PageImportController < ModuleController
  component_info 'Book'

  cms_admin_paths 'content', 
  'Content' => { :controller => '/content' }
  require 'csv'


  def index
    
    @book = BookBook.find(params[:path][0])
    cms_page_path ['Content'], [ 'Import Pages in %s',nil,@book.name ]

    if(request.post? && params[:import]) 
      @file = DomainFile.find_by_id(params[:import][:file])
      @fp = @file.filename
      if @book.check_header(@fp)       
        check_pages
      else
        @im_error = @book.errors.add(:error,'Invalid Header')
      end
    end

  end
  
  def check_pages
    @import_pages = []
    @@fields = [:id,:name,:description,:published,:body,:parent_id]

    reader = CSV.open(@fp,"r",",")
    reader.shift
    reader.each do |row|
      attr = {}
      @@fields.each_with_index { |field,idx| attr[field] = row[idx] }

      @page = @book.book_pages.find_by_id(attr[:id]) 
      @page_name = @book.book_pages.find_by_name(attr[:name]) 
      @page_parent = @book.book_pages.find_by_id(attr[:parent_id])

      if @page
        @import_pages.push([@page.name,"Updated"])
      elsif  @page_name
        @import_pages.push([@page_name.name,"Updated"])
      else
        @import_pages.push([attr[:name],"New"])
      end
    end
    return @import_pages
  end

  def confirm_import   
    @book = BookBook.find(params[:path][0])

    cms_page_path ['Content'], [ 'Import Pages in %s',nil,@book.name ]



    if(request.post? && params[:confirm_import])
      @file = DomainFile.find_by_id(params[:confirm_import][:csvfile])
      @fp =  @file.filename

      @book.do_import(@fp,myself)
    end
    redirect_to :controller => '/book/manage', :action => 'edit', :path => [ @book.id ]
    flash[:notice] = "Your pages have been imported"
  end
end







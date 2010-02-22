

class Book::PageImportController < ModuleController
  component_info 'Book'

 cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' }


  def index
    
    @book = BookBook.find(params[:path][0])
  #  raise @book.inspect
    cms_page_path ['Content'], [ 'Import Pages in %s',nil,@book.name ]

    @folder = DomainFile.root_folder

  end
end



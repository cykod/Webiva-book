

class Book::AdminController < ModuleController

  component_info 'Book', :description => 'Book support', 
                              :access => :private
                              
  # Register a handler feature
  register_permission_category :book, "Book" ,"Permissions related to Book"
  
  register_permissions :book, [ [ :manage, 'Manage Book', 'Manage Book' ],
                                  [ :config, 'Configure Book', 'Configure Book' ]
                                  ]

  content_action  'Create a new Book', { :controller => '/book/manage', :action => 'book' }, :permit => 'book_config'
  
  cms_admin_paths "options",
                   "Options" =>   { :controller => '/options' },
                   "Modules" =>  { :controller => '/modules' },
                   "Book Options" => { :action => 'index' }
  content_model :books
  
 public 

  def self.get_books_info
      info = BookBook.find(:all, :order => 'name').collect do |book| 
          {:name => book.name,:url => { :controller => '/book/manage', :action => 'edit', :path => book.id } ,:permission => :book_manage, :icon => 'icons/content/book_icon.png' }
      end 
      info
  end

    
 def options
    cms_page_path ['Options','Modules'],"Book Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated Book module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
  
  
  end
  
end

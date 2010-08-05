
class Book::AdminController < ModuleController

  component_info 'Book', :description => 'Book support', :access => :private
                              
  # Register a handler feature
  register_permission_category :book, "Book" ,"Permissions related to Book"
  
  register_permissions :book, [ [ :manage, 'Manage Book', 'Manage Book' ],
                                [ :config, 'Configure Book', 'Configure Book' ]
                              ]

  register_handler :webiva, :widget, "Book::SubmissionWidget"
  register_handler :structure, :wizard, "BookWizard"

  content_action  'Create a new Book', { :controller => '/book/manage', :action => 'book' }, :permit => 'book_config'
  
  content_model :books
  
  public 

  def self.get_books_info
    BookBook.find(:all, :order => 'name').collect do |book| 
      { :name => book.name,
        :url => { :controller => '/book/manage', :action => 'edit', :path => book.id },
        :permission => :book_manage,
        :icon => 'icons/content/book_icon.png'
      }
    end 
  end
end

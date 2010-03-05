# Copyright (C) 2010 Cykod LLC.

class Book::WizardController < ModuleController



   permit 'book_config'

  component_info 'Book'
  
  cms_admin_paths 'website'
  def self.structure_wizard_handler_info
    { 
      :name => "Add a Book to your Site",
      :description => 'This wizard will add an existing book to a url on your site.',
      :permit => "book_config",
      :url => { :controller => '/book/wizard' }
    }
  end


   def index
    cms_page_path ["Website"],"Add a Book to your site structure"

    @book_wizard = BookWizard.new(params[:wizard] || {  :book_id => params[:book_id].to_i})
    if request.post? 
      if !params[:commit] 
        redirect_to :controller => '/structure', :action => 'wizards'
      elsif  @book_wizard.valid?
        @book_wizard.add_to_site!
        flash[:notice] = "Added book to site"
        redirect_to :controller => '/structure'
      end
    end
  end

end

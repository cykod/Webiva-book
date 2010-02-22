require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + '/../../book_spec_helper'

describe Book::PageImportController do
  include BookSpecHelper
  
  reset_domain_tables :book_books, :book_pages, :book_page_versions, :domain_files
  
  describe 'page imports' do
    
    
    before(:each) do 
      mock_editor
      chapter_book
    end
    
    
    it 'should render the upload page' do 
      post('index', :path => [@cb.id])
      response.should render_template('book/page_import/index')
    end
  end
end

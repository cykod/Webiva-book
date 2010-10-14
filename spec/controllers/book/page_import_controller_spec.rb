require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + '/../../book_spec_helper'

describe Book::PageImportController do
  include BookSpecHelper
  
  reset_domain_tables :book_books, :book_pages, :book_page_versions, :domain_files
  
  describe 'page imports' do
    before(:each) do 
      mock_editor
      chapter_book

      @df = DomainFile.create(:filename => book_fixture_file_upload("/files/book-import.csv"))
    end
    
    after(:each) do
      @df.destroy 
    end
    
    it 'should render the upload page' do 
      get 'index', :path => [@cb.id]
      response.should render_template('book/page_import/index')
    end
    
    it 'should redirect to the confirm page' do 
      post 'index', :path => [@cb.id], :commit => 'Submit', :import => {:file => @df.id}
      response.should redirect_to :action => 'confirm', :path => [@cb.id, @df.id]
    end
    
    it 'should should have a matching header' do
      controller.should_receive(:check_pages)
      get 'confirm', :path => [@cb.id, @df.id]
    end
    
    it 'should import when confirmed' do
      BookBook.should_receive(:find).with(@cb.id).and_return(@cb)
      @cb.should_receive(:run_worker)
      post 'confirm', :path => [@cb.id, @df.id], :commit => 'Confirm'
    end
  end
end


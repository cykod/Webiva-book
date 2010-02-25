require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + '/../../book_spec_helper'

describe Book::PageImportController do
  include BookSpecHelper
  
  reset_domain_tables :book_books, :book_pages, :book_page_versions, :domain_files
  
  describe 'page imports' do
    
    
    before(:each) do 
      mock_editor
      chapter_book

      @folder = DomainFile.create_folder("My Folder")
      @folder.save
      fdata = fixture_file_upload("../../vendor/modules/book/spec/fixtures/files/book-import.csv")
      @df = DomainFile.create(:filename => fdata,:parent_id => @folder.id)
      fdata = fixture_file_upload("../../vendor/modules/book/spec/fixtures/files/book-import2.csv")
      @df2 = DomainFile.create(:filename => fdata,:parent_id => @folder.id)
    end
    
    after(:each) do
      @df.destroy 
      @df2.destroy

    end
    
    it 'should render the upload page' do 
      post('index', :path => [@cb.id])
      response.should render_template('book/page_import/index')
    end
    
    it 'should should have a matching header' do
      controller.should_receive(:check_pages)
      post('index', :path => [@cb.id], :import => {:file => 3} )      
    end
    
    it 'should should fail if header doesnt match' do
      controller.should_receive(:index).once.and_return(@im_error)
      post('index', :path => [@cb.id], :import => {:file => 4} )
    end
  
    it 'should create a list of import pages' do
      controller.should_receive(:check_pages).and_return(@import_pages)
      post('index', :path => [@cb.id], :import => {:file => 3} )
    end

    it 'should import when confirmed' do
      post('confirm_import', :commit => 'Confirm', :path => [@cb.id], :confirm_import => {:csvfile => 3} )
      @cb.book_pages.find(:all).count.should == 9
      @cb.book_pages.find_by_id(9).name.should == 'goose'
    end
    
  end
end


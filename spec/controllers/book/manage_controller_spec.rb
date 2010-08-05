require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../../book_spec_helper.rb"



describe Book::ManageController do
  include BookSpecHelper
  reset_domain_tables :book_books, :book_pages, :book_page_versions, :domain_files
  
  describe 'book' do 
    
    before(:each) do 
      mock_editor
      mock_user
      chapter_book
    end
    
    it 'should create a new sub page of @page1' do 
      assert_difference 'BookPage.count', 1 do
        post( 'add_to_tree', :path => [@cb.id], :page_id => @page1.id)
        @subpage = @cb.book_pages.find(:first, :order => 'id desc')
        @subpage.should_not be_nil
        @subpage.parent_id.should == @page1.id
        
      end
    end
    
    it 'should add a page above @page4' do 
      assert_difference 'BookPage.count', 1 do
        post( 'add_to_tree', :path => [@cb.id], :page_id => @page4.id, :position => 'top')
        @adjpage = @cb.book_pages.find(:first, :order => 'id desc')
        @adjpage.should_not be_nil
        @adjpage.parent_id.should == @cb.root_node.id
        @adjpage.lft.should == 8
      end
    end
    it 'should add a page below @page4' do 
      assert_difference 'BookPage.count', 1 do
        post( 'add_to_tree', :path => [@cb.id], :page_id => @page4.id, :position => 'bottom')
        @adjpage = @cb.book_pages.find(:first, :order => 'id desc')
        @adjpage.should_not be_nil
        @adjpage.lft.should == 10
        @adjpage.parent_id.should == @cb.root_node.id
      end
    end



    it 'should move page4 from position4 to position 1' do
      @root_node = @cb.book_pages.find_by_name("Root")
      @move = @root_node.id+1
      post( 'update_tree', :path => [@cb.id],  :chapter_tree => {@page4.id => {:left_id => '', :parent_id => '1'}})
      @subpage = @cb.book_pages.find_by_id(@page4.id)
      @subpage.lft.should == @move
    end
    

    it 'should be able to delete page4 in the book' do
      post( 'delete_page', :path => [@cb.id], :page_id => @page4.id);
      @doesexist = @cb.book_pages.find_by_id(@page4.id)
      @doesexist.should be_nil
    end

    
    it 'should be able to rename pages' do
      post( 'save_page', :path => [@cb.id], :page_id => @page4.id, :page => {:name => 'no longer page 4'} )
      @page4namechange = @cb.book_pages.find(@page4.id)
      @page4namechange.name.should == 'no longer page 4'
    end

    it 'should be able to preview pages' do
      BookBook.should_receive( :find ).and_return(@cb)
      book_pages = mock('book1')
      
      book_pages.should_receive( :find_by_id ).with( @page4.id.to_s ).and_return(@page4)
      @cb.should_receive( :book_pages ).and_return(book_pages)
      
      post( 'preview_page', :path => [@cb.id], :page_id => @page4.id, :page => {:body =>markdown_sample} )
      @page4.body_html.should == markdown_html
    end

    it 'should be able to delete the book' do
      post('delete', :path => [@cb.id], :kill => 'Destroy Book', :destroy => 'yes')
      @doesexist = BookBook.find_by_id(@cb.id)
      @doesexist.should be_nil
    end
    
    
    it 'should create default page if one does not exist' do
      post('book', :path => '', :action => 'book', :commit => 'Submit', :book => { :book_type => 'chapter',:url_scheme => 'flat', :name => 'Books should have default page' ,:created_by_id => mock_user.id})

      @blank_chapter_book = BookBook.find_by_name('Books should have default page')
      post('edit', :path => [@blank_chapter_book.id])
      @defaultpage = @blank_chapter_book.book_pages.find(:last, :order => 'id asc')
      @defaultpage.name.should == 'Default Page'
      @defaultpage.id.should == 8
    end
  end
  
  
    describe 'book1' do 
    
      before(:each) do 
        mock_editor
        flat_book
      end
      
      it 'should create a flat book' do
        assert_difference 'BookBook.count', 1 do
          post( 'book', :path => [], :commit => 'Submit', :book => {:cover_file_id => '', :name => @rand_name_f, :url_scheme => 'flat', :thumb_file_id => '', :preview_wrapper => '', :book_type => 'flat', :description => '', :style_template_id => '', :image_folder_id => '', :content_filter => 'markdown'} ,:created_by_id => @myself.id)
          @newflatbook = BookBook.find(:last)
          @newflatbook.name.should == @rand_name_f
        end
        
    end

    
    it 'should create a page in a flat book' do
      assert_difference 'BookPage.count', 1 do

        post( 'save_page', :path => [@flatbook.id], :page_id => '', :page => { :name => @rand_name_f, :body => '', :published => 'true', :description => '' } )
        @newpage = @flatbook.book_pages.find_by_name(@rand_name_f)
        @newpage.should_not be_nil
      end
    end
    
    
    it 'should be able to delete page4 in the book1' do
      post( 'delete_page', :path => [@flatbook.id], :page_id => @page4.id);
      @doesexist = @flatbook.book_pages.find_by_id(@page4.id)
      @doesexist.should be_nil
    end

    
    it 'should be able to rename pages1' do
      post( 'save_page', :path => [@flatbook.id], :page_id => @page4.id, :page => {:name => 'no longer page 4'} )
      @page4namechange = @flatbook.book_pages.find(@page4.id)
      @page4namechange.name.should == 'no longer page 4'
    end


 it 'should be able to preview pages1' do
      BookBook.should_receive( :find ).and_return(@flatbook)
      book_pages = mock('book1')
      
      book_pages.should_receive( :find_by_id ).with( @page4.id.to_s ).and_return(@page4)
      @flatbook.should_receive( :book_pages ).and_return(book_pages)
      
      post( 'preview_page', :path => [@flatbook.id], :page_id => @page4.id, :page => {:body =>markdown_sample} )
      @page4.body_html.should == markdown_html
    end

    
  end
  
  
  describe 'versions' do
    before(:each) do 
      mock_editor
    end
    
    it 'should create a version for a page in a chapter book' do
      chapter_book

      assert_difference 'BookPageVersion.count', 1 do
        post( 'add_to_tree', :path => [@cb.id], :page_id => @cb.root_node.id)
        @rev = @cb.book_page_versions.find(:first, :order => 'id desc')
      end
    end

    it 'should create a version for a new flat book page' do
      flat_book

      assert_difference 'BookPageVersion.count', 1 do
        post( 'save_page', :path => [@flatbook.id], :page_id => @page1.id, :page => {:name => @rand_name_f, :body => "1"})
        prev = @flatbook.book_page_versions.find(:first, :order => 'id desc')
      end
    end
  end
end







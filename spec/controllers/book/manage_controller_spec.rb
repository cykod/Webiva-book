require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"



describe Book::ManageController do
  reset_domain_tables :book_books, :book_pages, :book_page_versions, :domain_files
  
  describe 'book' do 
    
    before(:each) do 
      mock_editor

      def random_string(size=12)
        (1..size).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
      end
      @rand_name = random_string

      @cb = BookBook.create(:name => 'chapter book')
      @page1 = @cb.book_pages.create(:name => 'chapter one' )
      @page1.move_to_child_of(@cb.root_node)
      @page2 = @cb.book_pages.create(:name => 'chapter two' )
      @page2.move_to_child_of(@cb.root_node)
      @page3 = @cb.book_pages.create(:name => 'chapter three')
      @page3.move_to_child_of(@cb.root_node)
      @page4 = @cb.book_pages.create(:name => 'chapter four' )
      @page4.move_to_child_of(@cb.root_node)
      @page5 = @cb.book_pages.create(:name => 'chapter five' )
      @page5.move_to_child_of(@cb.root_node)
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
      post( 'update_tree', :path => [@cb.id],  :chapter_tree => {@page4.id => {:left_id => '', :parent_id => '1'}})
      @subpage = @cb.book_pages.find_by_id(@page4.id)
      @subpage.lft.should == 2
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
      
      book_pages.should_receive( :find ).with( @page4.id.to_s ).and_return(@page4)
      @cb.should_receive( :book_pages ).and_return(book_pages)
      
      post( 'preview_page', :path => [@cb.id], :page_id => @page4.id, :page => {:body => 
              "preview fun markdown\n===================="} )
      @page4.body_html.should == "<h1 id='preview_fun_markdown'>preview fun markdown</h1>"
    end

    it 'should be able to delete the book' do
      post('delete', :path => [@cb.id], :kill => 'Destroy Book', :destroy => 'yes')

#      @doesexist = BookBook.find_by_id(@cb.id)
 #     @doesexist.should be_nil
    end


    it 'should create default page if one does not exist' do
      post('book', :path => '', :action => 'book', :commit => 'Submit', :book => { :book_type => 'chapter',:url_scheme => 'flat', :name => 'Books should have default page'})

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
      
      

      def random_string(size=12)
        (1..size).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
      end
      @rand_name = random_string

      @flatbook =  BookBook.create(:book_type => 'flat', :name => 'flat book')
      @page1 = @flatbook.book_pages.create(:name => 'a flat one' )
      @page2 = @flatbook.book_pages.create(:name => 'b flat two' )
      @page3 = @flatbook.book_pages.create(:name => 'c flat three')
      @page4 = @flatbook.book_pages.create(:name => 'd flat four' )
      @page5 = @flatbook.book_pages.create(:name => 'e flat five' )
    end
    
    it 'should create a flat book' do
      assert_difference 'BookBook.count', 1 do
        post( 'book', :path => [], :commit => 'Submit', :book => {:cover_file_id => '', :name => @rand_name, :url_scheme => 'flat', :thumb_file_id => '', :preview_wrapper => '', :book_type => 'flat', :description => '', :style_template_id => '', :image_folder_id => '', :content_filter => 'markdown'} )
        @newflatbook = BookBook.find(:last)
        @newflatbook.name.should == @rand_name
      end

    end

    
    it 'should create a page in a flat book' do
      assert_difference 'BookPage.count', 1 do
        post( 'save_page', :path => [@flatbook.id], :page_id => '', :page => { :name => @rand_name, :body => '', :published => 'true', :description => '' } )
        @newpage = @flatbook.book_pages.find_by_name(@rand_name)
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

    it 'should be able to preview pages' do
      BookBook.should_receive( :find ).and_return(@flatbook)
      book_pages = mock('book1')
      
      book_pages.should_receive( :find ).with( @page4.id.to_s ).and_return(@page4)
      @flatbook.should_receive( :book_pages ).and_return(book_pages)
      
      post( 'preview_page', :path => [@flatbook.id], :page_id => @page4.id, :page => {:body => 
              "preview fun markdown\n===================="} )
      @page4.body_html.should == "<h1 id='preview_fun_markdown'>preview fun markdown</h1>"
    end

    
  end
  
  
  describe 'autosave' do

  before(:each) do 
      mock_editor

      def random_string(size=12)
        (1..size).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
      end
      @rand_name = random_string

      @cb = BookBook.create(:name => 'chapter book')
      @page1 = @cb.book_pages.create(:name => 'chapter one' )
      @page1.move_to_child_of(@cb.root_node)
      @page2 = @cb.book_pages.create(:name => 'chapter two' )
      @page2.move_to_child_of(@cb.root_node)

    end
    
    it 'should create an autosave version' do

      post('save_draft', 
           :path => [@cb.id], 
           :page_id => @page1.id, 
           :page => {
             :name => @page1.name, 
             :book_book_id => @cb.id, 
             :book_page_id => @page1.id, 
             :body => 'oh isnt this fun'} )
   
      @version = @cb.book_page_versions.find(:last, :order => 'updated_at', :conditions => {:version_status => 'draft' })

      @version.id.should == 4
          
    end
    it 'should update that same auto save version ' do
 # it is important for the draft save not to add
 #  a new record on save, it should update the existing record
       post('save_draft', 
           :path => [@cb.id], 
           :page_id => @page1.id, 
           :page => {
             :name => @page1.name, 
             :book_book_id => @cb.id, 
             :book_page_id => @page1.id, 
             :body => ' isnt this fun'} )

      @version = @cb.book_page_versions.find(:last, :order => 'updated_at', :conditions => {:version_status => 'draft' })
      
      @version.id.should == 4


      post('save_draft', 
           :path => [@cb.id], 
           :page_id => @page1.id, 
           :version_id => @version.id,
           :page => {
             :name => @page1.name, 
             :book_book_id => @cb.id, 
             :book_page_id => @page1.id, 
             :body => ' isnt this funner'} )
      
      @ver = @cb.book_page_versions.find_by_id(@version.id)
      @ver.body.should == ' isnt this funner'
      @ver.id.should == @version.id

    end
  end
  describe 'bulk editing' do
     before(:each) do 
      mock_editor

      def random_string(size=12)
        (1..size).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
      end
      @rand_name = random_string

      @cb = BookBook.create(:name => 'chapter book')
      @page1 = @cb.book_pages.create(:name => 'chapter one' )
      @page1.move_to_child_of(@cb.root_node)
      @page2 = @cb.book_pages.create(:name => 'chapter two' )
      @page2.move_to_child_of(@cb.root_node)
      @page3 = @cb.book_pages.create(:name => 'chapter three')
      @page3.move_to_child_of(@cb.root_node)
      @page4 = @cb.book_pages.create(:name => 'chapter four' )
      @page4.move_to_child_of(@cb.root_node)
      @page5 = @cb.book_pages.create(:name => 'chapter five' )
      @page5.move_to_child_of(@cb.root_node)
    end
  
    
    it 'should create and perform actions on an active table' do
      
      controller.should handle_active_table(:bulkview_table) do |args|
        args ||= {}
        args[:path] = [@cb.id]
        post 'display_bulkview_table', args
      end
    end
    
    it 'should delete a page in the bulkview_table' do
      post 'display_bulkview_table', :path => [@cb.id], :table_action => 'delete', :bulkview => {@page2.id => @page2.id}
      @pg_count = @cb.book_pages.find(:all).count
      @pg_count.should == 5;
    end
    
    it 'should publish a page in the bulkview_table' do
      post 'display_bulkview_table', :path => [@cb.id], :table_action => 'publish', :bulkview => {@page2.id => @page2.id}
      @pg = @cb.book_pages.find(@page2.id)
      @pg.published.should be true;
    end
    it 'should unpublish a page in the bulkview_table' do
      post 'display_bulkview_table', :path => [@cb.id], :table_action => 'unpublish', :bulkview => {@page2.id => @page2.id}
      @pg = @cb.book_pages.find(@page2.id)
      @pg.published.should be false;

    end
    
    it 'should render a form for a list of page ids' do      
      post('add_subpages_form',:page_ids => ["3", "6"], :path => [@cb.id]) 
      response.should render_template('book/manage/_add_subpages_form')
      
    end
    
    it 'should add new subpages to page2 and page5' do
      post('add_subpages_form', :new_page => {:page_names =>{'3' => "onepage", '6' => "twopage"}}, :path => [@cb.id])
      @subpage = @cb.book_pages.find_by_name('onepage')
      @subpage.id.should == 8
      @subpage.parent_id.should == 3
    end
    it 'should  render the meta data form' do
      post('edit_meta_form', :path=>[@cb.id],:page_id =>["3"])
      response.should render_template('book/manage/_edit_meta_form')
    end
    it 'should update meta data to page1' do
      post('edit_meta_form', :path=>[@cb.id], :update_page=>{:reference=>"reference", :name=> "change name", :id => @page1.id, :description=>"descrip"}  )
      @meta_update = @cb.book_pages.find_by_id(@page1.id)
      @meta_update.name.should == 'change name'
      response.should render_template('book/manage/edit_meta_form.rjs')
    end
  end
  
  
  
  
  
end


  











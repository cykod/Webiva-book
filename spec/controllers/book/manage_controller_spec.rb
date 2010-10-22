require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../../book_spec_helper.rb"

describe Book::ManageController do
  include BookSpecHelper
  reset_domain_tables :book_books, :book_pages, :book_page_versions, :domain_files
  
  it 'verify tree structure' do
    chapter_book

    @cb.root_node.lft.should == 1
    @cb.root_node.rgt.should == 12
    @cb.root_node.parent_id.should be_nil

    @page1.lft.should == 2
    @page1.rgt.should == 3
    @page1.parent_id.should == @cb.root_node.id

    @page2.lft.should == 4
    @page2.rgt.should == 5
    @page2.parent_id.should == @cb.root_node.id

    @page3.lft.should == 6
    @page3.rgt.should == 11
    @page3.parent_id.should == @cb.root_node.id

    @page4.lft.should == 7
    @page4.rgt.should == 10
    @page4.parent_id.should == @page3.id

    @page5.lft.should == 8
    @page5.rgt.should == 9
    @page5.parent_id.should == @page4.id
  end

  describe 'Chapter Book' do
    before(:each) do 
      mock_editor
      chapter_book
    end

    it 'should render create a book' do
      get 'book', :path => []
    end

    it 'should render configure book' do
      get 'book', :path => [@cb.id]
    end

    it 'should create a book' do
      assert_difference 'BookBook.count', 1 do
        post('book', :path => [], :commit => 'Submit', :book => {:book_type => 'chapter', :url_scheme => 'flat', :name => 'New Book', :add_to_site => false})
      end

      @book = BookBook.last
      @book.name.should == 'New Book'
      @book.book_type.should == 'chapter'
      @book.url_scheme.should == 'flat'

      response.should redirect_to(:action => 'edit', :path => [@book.id])
    end

    it 'should create a book' do
      assert_difference 'BookBook.count', 1 do
        post('book', :path => [], :commit => 'Submit', :book => {:book_type => 'chapter', :url_scheme => 'flat', :name => 'New Book', :add_to_site => true})
      end

      @book = BookBook.last
      @book.name.should == 'New Book'
      @book.book_type.should == 'chapter'
      @book.url_scheme.should == 'flat'

      response.should redirect_to(:controller => '/structure', :action => 'wizard', :path => ['book_wizard'], :book_id => @book.id, :version => SiteVersion.default.id)
    end

    it 'should edit a book' do
      @cb.name.should_not == 'New Book'

      assert_difference 'BookBook.count', 0 do
        post('book', :path => [@cb.id], :commit => 'Submit', :book => {:book_type => 'flat', :url_scheme => 'id', :name => 'New Book'})
      end

      @book = BookBook.find @cb.id
      @book.name.should == 'New Book'
      @book.book_type.should == 'chapter'
      @book.url_scheme.should == 'flat'

      response.should redirect_to(:action => 'edit', :path => [@book.id])
    end

    it 'should not create a book' do
      assert_difference 'BookBook.count', 0 do
        post('book', :path => [], :book => {:book_type => 'chapter', :url_scheme => 'flat', :name => 'New Book', :add_to_site => true})
      end

      response.should redirect_to(:controller => '/content')
    end

    it 'should not edit a book' do
      @cb.name.should_not == 'New Book'

      assert_difference 'BookBook.count', 0 do
        post('book', :path => [@cb.id], :book => {:name => 'New Book'})
      end

      @book = BookBook.find @cb.id
      @book.name.should_not == 'New Book'

      response.should redirect_to(:action => 'edit', :path => [@book.id])
    end

    it 'should display edit page' do
      assert_difference 'BookPage.count', 0 do
        get 'edit', :path => [@cb.id]
      end
    end

    it 'should display edit page and create a page if a chapter book has no pages' do
      @book = BookBook.create :name => 'New Book'
      # creates root node and new default page
      assert_difference 'BookPage.count', 2 do
        get 'edit', :path => [@book.id]
      end
    end

    it 'should create a new sub page of page1' do
      assert_difference 'BookPage.count', 1 do
        post( 'add_to_tree', :path => [@cb.id], :page_id => @page1.id)
      end

      @page1.reload

      @subpage = BookPage.last
      @subpage.parent_id.should == @page1.id
      @subpage.lft.should == 3
      @subpage.rgt.should == 4
      @page1.lft.should == 2
      @page1.rgt.should == 5
    end
    
    it 'should add a page above @page4' do
      assert_difference 'BookPage.count', 1 do
        post( 'add_to_tree', :path => [@cb.id], :page_id => @page4.id, :position => 'top')
      end

      @page4.reload

      @adjpage = BookPage.last
      @adjpage.parent_id.should == @page4.parent_id
      @adjpage.lft.should == 7
      @adjpage.rgt.should == 8
      @page4.lft.should == 9
      @page4.rgt.should == 12
    end

    it 'should add a page below @page4' do 
      assert_difference 'BookPage.count', 1 do
        post( 'add_to_tree', :path => [@cb.id], :page_id => @page4.id, :position => 'bottom')
      end

      @page4.reload

      @page4.lft.should == 7
      @page4.rgt.should == 10

      @adjpage = BookPage.last
      @adjpage.parent_id.should == @page4.parent_id
      @adjpage.lft.should == 11
      @adjpage.rgt.should == 12
    end

    it 'should update tree' do
      post 'update_tree', :path => [@cb.id],  :chapter_tree => {@page4.id => {:left_id => nil, :parent_id => @page2.id}}

      @page2.reload
      @page4.reload

      @page2.lft.should == 4
      @page2.rgt.should == 9

      @page4.lft.should == 5
      @page4.rgt.should == 8
    end

    it 'should update tree' do
      post 'update_tree', :path => [@cb.id],  :chapter_tree => {@page2.id => {:left_id => nil, :parent_id => @page3.id}}

      @page2.reload
      @page3.reload

      @page3.lft.should == 4
      @page3.rgt.should == 11

      @page2.lft.should == 5
      @page2.rgt.should == 6
    end

    it 'should update tree' do
      post 'update_tree', :path => [@cb.id],  :chapter_tree => {@page2.id => {:left_id => @page4.id, :parent_id => @page3.id}}

      @page2.reload
      @page3.reload

      @page3.lft.should == 4
      @page3.rgt.should == 11

      @page2.lft.should == 9
      @page2.rgt.should == 10
    end

    it "should display a page" do
      get 'page', :path => [@cb.id], :page_id => @page1.id
    end

    it "should display a new page" do
      get 'page', :path => [@cb.id]
    end

    it 'should be able to rename pages' do
      assert_difference 'BookPageVersion.count', 1 do
        post 'save_page', :path => [@cb.id], :page_id => @page4.id, :page => {:name => 'no longer page 4'}
      end

      @page4.reload
      @page4.name.should == 'no longer page 4'
    end

    it 'should be able to save page and remove the draft version' do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'page', 'draft', nil)
      @version.id.should_not be_nil

      assert_difference 'BookPageVersion.count', 0 do
        post 'save_page', :path => [@cb.id], :page_id => @page4.id, :page => {:name => 'no longer page 4'}, :draft_id => @version.id
      end

      BookPageVersion.find_by_id(@version.id).should be_nil

      @page4.reload
      @page4.name.should == 'no longer page 4'
    end

    it 'should be able to save draft' do
      assert_difference 'BookPageVersion.count', 1 do
        post 'save_draft', :path => [@cb.id], :page_id => @page4.id, :page => {:body => 'new version body'}
      end

      @page4.reload
      @page4.body.should_not == 'new version body'

      @version = @page4.book_page_versions.last
      @version.body.should == 'new version body'
    end

    it 'should be able to save draft' do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'page', 'draft', nil)
      @version.id.should_not be_nil

      assert_difference 'BookPageVersion.count', 0 do
        post 'save_draft', :path => [@cb.id], :page_id => @page4.id, :page => {:body => 'new version body'}, :version_id => @version.id
      end

      @page4.reload
      @page4.body.should_not == 'new version body'

      @version = @page4.book_page_versions.last
      @version.body.should == 'new version body'
    end

    it "should be able to search" do
      get 'search', :path => [@cb.id], :search => 'chapter'
    end

    it 'should be able to preview pages' do
      post( 'preview_page', :path => [@cb.id], :page_id => @page4.id, :page => {:body =>markdown_sample} )
    end

    it 'should be able to delete page4 in the book' do
      post 'delete_page', :path => [@cb.id], :page_id => @page4.id
      @cb.book_pages.find_by_id(@page4.id).should be_nil
    end

    it 'should be able to delete the book' do
      post 'delete', :path => [@cb.id], :kill => 'Destroy Book', :destroy => 'yes'
      BookBook.find_by_id(@cb.id).should be_nil
    end

    it "should handle version table list" do
      controller.should handle_active_table(:version_table) do |args|
        args ||= {}
        args[:path] = [@cb.id]
        args[:page_id] = @page4.id
        post 'display_version_table', args
      end
    end

    it "should be able to delete a version" do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'wiki', 'submitted', nil)
      assert_difference 'BookPageVersion.count', -1 do
        post 'display_version_table', :path => [@cb.id], :page_id => @page4.id, :version => {@version.id => @version.id}, :table_action => 'delete'
      end
      BookPageVersion.find_by_id(@version.id).should be_nil
    end

    it "should be able to review a version" do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'wiki', 'submitted', nil)
      post 'display_version_table', :path => [@cb.id], :page_id => @page4.id, :version => {@version.id => @version.id}, :table_action => 'reviewed'
      @version.reload
      @version.version_status.should == 'reviewed'
    end

    it "should render edits page" do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'wiki', 'submitted', nil)
      get 'edits', :path => [@cb.id]
    end

    it "should handle edits table list" do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'wiki', 'submitted', nil)
      controller.should handle_active_table(:edits_table) do |args|
        args ||= {}
        args[:path] = [@cb.id]
        post 'display_edits_table', args
      end
    end

    it "should be able to delete a version" do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'wiki', 'submitted', nil)
      assert_difference 'BookPageVersion.count', -1 do
        post 'display_edits_table', :path => [@cb.id], :page_id => @page4.id, :version => {@version.id => @version.id}, :table_action => 'delete'
      end
      BookPageVersion.find_by_id(@version.id).should be_nil
    end

    it "should be able to review a version" do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'wiki', 'submitted', nil)
      post 'display_edits_table', :path => [@cb.id], :page_id => @page4.id, :version => {@version.id => @version.id}, :table_action => 'reviewed'
      @version.reload
      @version.version_status.should == 'reviewed'
    end

    it 'should be able view wiki edits' do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'wiki', 'submitted', nil)
      @version.id.should_not be_nil
      get 'view_wiki_edits', :path => [@cb.id], :version_id => @version.id
    end

    it 'should be able review wiki edits' do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'wiki', 'submitted', nil)
      @version.id.should_not be_nil
      @version.version_status.should == 'submitted'
      post 'review_wiki_edits', :path => [@cb.id], :version_id => @version.id
      @version.reload
      @version.version_status.should == 'reviewed'
      @page4.reload
      @page4.body.should_not == 'my new draft version'
    end

    it 'should be able accept wiki edits' do
      @version = @page4.save_version(@myself.id, 'my new draft version', 'wiki', 'submitted', nil)
      @version.id.should_not be_nil
      @version.version_status.should == 'submitted'
      assert_difference 'BookPageVersion.count', 1 do
        post 'accept_wiki_edits', :path => [@cb.id], :version_id => @version.id
      end

      @version.reload
      @version.version_status.should == 'reviewed'

      @page4.reload
      @page4.body.should == 'my new draft version'

      @version = @page4.book_page_versions.last
      @version.version_status.should == 'accepted wiki'
      @version.version_type.should == 'admin editor'
    end

    it "should be able to render add subpages" do
      get 'add_subpages_form', :path => [@cb.id], :page_ids => [@page2.id, @page5.id]
    end

    it "should be able to bulk add subpages" do
      assert_difference 'BookPage.count', 3 do
        post 'add_subpages_form', :path => [@cb.id], :new_page => {:page_names => {@page2.id => 'New Page2', @page5.id => "New Page 5\nNew Page 6"}}
      end
      BookPage.find_by_name('New Page 6').parent_id.should == @page5.id
    end

    it "should be able to render meta form" do
      get 'edit_meta_form', :path => [@cb.id], :page_id => @page2.id
    end

    it "should be able to update meta data" do
      post 'edit_meta_form', :path => [@cb.id], :update_page => {:id => @page2.id, :name => 'New Page Name', :description => "new description", :reference => 'new-reference'}
      @page2.reload
      @page2.name.should == 'New Page Name'
      @page2.description.should == 'new description'
      @page2.reference.should == 'new-reference'
    end

    it "should render bulk edit page" do
      get 'bulk_edit', :path => [@cb.id]
    end

    it "should handle bulk view table list" do 
      controller.should handle_active_table(:bulkview_table) do |args|
        args ||= {}
        args[:path] = [@cb.id]
        post 'display_bulkview_table', args
      end
    end

    it "should be able to publish pages" do
      @page2.update_attribute :published, false
      @page3.update_attribute :published, false
      post 'display_bulkview_table', :path => [@cb.id], :bulkview => {@page2.id => @page2.id, @page3.id => @page3.id}, :table_action => 'publish'
      @page2.reload
      @page3.reload
      @page2.published.should be_true
      @page3.published.should be_true
    end

    it "should be able to unpublish pages" do
      post 'display_bulkview_table', :path => [@cb.id], :bulkview => {@page2.id => @page2.id, @page3.id => @page3.id}, :table_action => 'unpublish'
      @page2.reload
      @page3.reload
      @page2.published.should be_false
      @page3.published.should be_false
    end

    it "should be able to delete pages" do
      assert_difference 'BookPage.count', -4 do
        post 'display_bulkview_table', :path => [@cb.id], :bulkview => {@page2.id => @page2.id, @page3.id => @page3.id}, :table_action => 'delete'
      end
      BookPage.find_by_id(@page2.id).should be_nil
      BookPage.find_by_id(@page3.id).should be_nil
    end
  end
  
  
  describe 'Flat Book' do
    before(:each) do
      mock_editor
    end

    it 'should create a flat book' do
      assert_difference 'BookBook.count', 1 do
        post 'book', :path => [], :commit => 'Submit', :book => {:name => 'My Flat Book', :book_type => 'flat'}
        @book = BookBook.last
        @book.book_type.should == 'flat'
      end
    end

    it 'should display edit page, but it does not create a page for a flat book' do
      @book = BookBook.new :name => 'New Book'
      @book.book_type = 'flat'
      @book.save
      assert_difference 'BookPage.count', 0 do
        get 'edit', :path => [@book.id]
      end
    end
  end
end

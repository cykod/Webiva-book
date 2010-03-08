
require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"


describe BookWizard do
  
  reset_domain_tables :book_books, :book_pages, :book_page_versions, :page_paragraphs, :content_types, :page_revisions, :site_nodes,  :content_nodes

  
  before(:each) do
    @book = BookBook.new(:name => "Test Auto Create Book")
  end
  it 'should create a page, book-display, for displaying the book' do
    root_node = SiteVersion.default.root_node.add_subpage('book-display')
    SiteNode.find_by_node_path('/book-display').should_not be_nil   
  end
  it 'should add a book to the book-display page' do
    root_node = SiteVersion.default.root_node.add_subpage('book-test')

    wizard = BookWizard.new(
                                  :book_id => @book.id,
                                  :add_to_id => root_node.id,
                                  :add_to_subpage => 'book'
                                  )
    wizard.add_to_site!
    @bookpage = SiteNode.find_by_node_path('/book')
    @bookpage.should_not be_nil
    para = @bookpage.page_revisions[0].page_paragraphs
    para[0].display_type.should == 'html'
    para[1].display_type.should == 'content'
  end


  it 'should add a chapters list paragraph to the book-display page' do
    root_node = SiteVersion.default.root_node.add_subpage('book-test')

    wizard = BookWizard.new(
                            :book_id => @book.id,
                            :add_to_id => root_node.id,
                            :add_to_subpage => 'book',
                            :opts => ["chapters"]

                                  )
    wizard.add_to_site!
    SiteNode.find_by_node_path('/book').should_not be_nil
  end
  it 'should add a comments block to book pages' do
    root_node = SiteVersion.default.root_node.add_subpage('book-test')

    wizard = BookWizard.new(
                            :book_id => @book.id,
                            :add_to_id => root_node.id,
                            :add_to_subpage => 'book',
                            :wiki_page_url => 'edit2',
                            :opts => ["","comments"]
                            )
    wizard.add_to_site!
    @bookpage = SiteNode.find_by_node_path('/book')
    @bookpage.should_not be_nil
    
    para = @bookpage.page_revisions[0].page_paragraphs
    para[0].display_type.should == 'html'
    para[1].display_type.should == 'content'
    para[2].display_type.should == 'comments'

  end
  it 'should add a wiki to a book on the site' do
    root_node = SiteVersion.default.root_node.add_subpage('book-test')

    wizard = BookWizard.new(
                            :book_id => @book.id,
                            :add_to_id => root_node.id,
                            :add_to_subpage => 'book',
                            :wiki_page_url => 'edit2',
                            :opts => ["wiki"]

                                  )
    wizard.add_to_site!
    SiteNode.find_by_node_path('/book').should_not be_nil
    @wikipage = SiteNode.find_by_node_path('/book/edit2')
    @wikipage.should_not be_nil

    para = @wikipage.page_revisions[0].page_paragraphs
    para[0].display_type.should == 'html'
    para[1].display_type.should == 'wiki_editor'
    
  end
end

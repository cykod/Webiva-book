require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../book_spec_helper.rb"

describe BookPage do
  include BookSpecHelper

  reset_domain_tables :book_books, :book_pages, :book_page_versions, :domain_files

  it "should be able to add pages to a book" do

    @book = BookBook.create(:name => 'book', :created_by_id => mock_editor.id)

    @book.root_node.should_not be_nil

    @page = @book.book_pages.create(:name => 'Test Page',
                                    :created_by_id => mock_editor.id)
    @page.move_to_child_of(@book.root_node)

    @page.parent_id.should == @book.root_node.id
  end

  it "should correctly filter content" do
    @folder = DomainFile.create_folder("My Folder")
    @folder.save
    fdata = fixture_file_upload("/files/rails.png",'image/png')
    @df = DomainFile.new(:filename => fdata,:parent_id => @folder.id)
    
   

    @book = BookBook.create(:name => 'book',
                            :created_by_id => mock_editor.id,
                            :content_filter => 'markdown',
                            :image_folder_id => @folder.id)

    
    
    @page = @book.book_pages.create(:name => 'Test Page',
                                    :body => markdown_sample(),
                                    :created_by_id => mock_editor.id)

    @page.move_to_child_of(@book.root_node)

    @page.body_html.should == markdown_html
  end
  
  it "should create new proper page links" do
    markdown_sample2 = <<EOF  

Link One : [[yes title]](linktext)  
  
Link Two : [[no title]]
EOF

    markdown_html2 = <<EOF.strip

<p>Link One : <a href='linktext'>yes title</a></p>

<p>Link Two : <a href='no-title'>no title</a></p>
EOF

    @book = BookBook.create(:name => 'book',
                            :content_filter => 'markdown',
                            :created_by_id => mock_editor.id)

    
    
    @page = @book.book_pages.create(:name => 'Test Page',
                                    :body => markdown_sample2,
                                    :created_by_id => mock_editor.id)

    @page.move_to_child_of(@book.root_node)

    @page.body_html.should == markdown_html2
  end

  it "should be able to find adjacent pages" do
    chapter_book

    @page6 = @cb.book_pages.create(:name => 'chapter six')
    @page6.move_to_child_of(@page3)

    @page1.reload
    @page2.reload
    @page3.reload
    @page4.reload
    @page5.reload
    @page6.reload

    # Chapter Book layout
    # <page>
    # page 1
    # page 2
    # page 3
    #  * page 4
    #     * page 5
    #  * page 6

    @page1.parent_page.should be_nil
    @page2.parent_page.should be_nil
    @page3.parent_page.should be_nil
    @page4.parent_page.should == @page3
    @page5.parent_page.should == @page4
    @page6.parent_page.should == @page3

    @page1.next_page.should == @page2
    @page2.next_page.should == @page3
    @page3.next_page.should == @page4
    @page4.next_page.should == @page5
    @page5.next_page.should be_nil
    @page6.next_page.should be_nil

    @page1.previous_page.should be_nil
    @page2.previous_page.should == @page1
    @page3.previous_page.should == @page2
    @page4.previous_page.should be_nil
    @page5.previous_page.should be_nil
    @page6.previous_page.should == @page4

    @page1.forward_page.should == @page2
    @page2.forward_page.should == @page3
    @page3.forward_page.should == @page4
    @page4.forward_page.should == @page5
    @page5.forward_page.should == @page6
    @page6.forward_page.should be_nil

    @page1.back_page.should be_nil
    @page2.back_page.should == @page1
    @page3.back_page.should == @page2
    @page4.back_page.should == @page3
    @page5.back_page.should == @page4
    @page6.back_page.should == @page5
  end

  it "should change the url if it is blank" do
    @book = BookBook.create :name => 'book'
    @page1 = @book.book_pages.create :name => 'New Page'
    @page1.url.should be_nil
    @page1.path.should be_nil

    @page1.update_attribute :name, 'New Page 2'
    @page1.url.should == 'new-page-2'
    @page1.path.should == '/new-page-2'

    @page1.update_attributes :name => 'Page 2', :url => ''
    @page1.url.should == 'page-2'
    @page1.path.should == '/page-2'

    @page1.update_attribute :name, 'New Name'
    @page1.url.should == 'page-2'
    @page1.path.should == '/page-2'

    @page1.update_attributes :name => 'New Name', :url => 'test'
    @page1.url.should == 'test'
    @page1.path.should == '/test'
  end

  it "should be able to use id scheme" do
    @book = BookBook.new :name => 'book'
    @book.url_scheme = 'id'
    @book.save

    @page1 = @book.book_pages.create :name => 'New Page'
    @page1.url.should == "#{@page1.id}"
    @page1.path.should == "/#{@page1.id}"
  end

  it "should be able to use nested scheme" do
    @book = BookBook.new :name => 'book'
    @book.url_scheme = 'nested'
    @book.save

    @page1 = @book.book_pages.create :name => 'Page1'
    @page1.url.should == "page1"
    @page1.path.should == "/page1"

    @page2 = @book.book_pages.create :name => 'Page2'
    @page2.move_to_child_of(@page1)
    @page2.url.should == "page2"
    @page2.path.should == "/page1/page2"

    @page3 = @book.book_pages.create :name => 'Page3'
    @page3.move_to_child_of(@page2)
    @page3.url.should == "page3"
    @page3.path.should == "/page1/page2/page3"

    @page1.reload
    @page2.reload
    @page3.reload

    @page2.move_to_child_of(@book.root_node)

    @page1.reload
    @page2.reload
    @page3.reload

    @page1.path.should == '/page1'
    @page2.path.should == '/page2'
    @page3.path.should == '/page2/page3'
  end
end

  

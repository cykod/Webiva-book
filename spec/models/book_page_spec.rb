
require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"


describe BookPage do
  
  reset_domain_tables :book_books, :book_pages, :book_page_versions, :domain_files


  it "should be able to add pages to a book" do

    @book = BookBook.create(:name => 'book')

    @book.root_node.should_not be_nil

    @page = @book.book_pages.create(:name => 'Test Page')
    @page.move_to_child_of(@book.root_node)

    @page.parent_id.should == @book.root_node.id
  end

  it "should correctly filter content" do

    @folder = DomainFile.create_folder("My Folder")
    @folder.save
    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata,:parent_id => @folder.id)
    
    markdown_sample = <<EOF
Hello Nurse
==========

This is a test of the emergency broadcast system, this is only a test.

![Rails](images/rails.png)
EOF

    markdown_html = <<EOF.strip
<h1 id='hello_nurse'>Hello Nurse</h1>

<p>This is a test of the emergency broadcast system, this is only a test.</p>

<p><img src='#{@df.url}' alt='Rails' /></p>
EOF

    @book = BookBook.create(:name => 'book',
                            :content_filter => 'markdown',
                            :image_folder_id => @folder.id)

    
    
    @page = @book.book_pages.create(:name => 'Test Page',
                                    :body => markdown_sample)

    @page.move_to_child_of(@book.root_node)

    @page.body_html.should == markdown_html
  end
  
    it "should create proper page links" do
    markdown_sample = <<EOF  

Link One : [[yes title]](linktext)  
  
Link Two : [[no title]]
EOF

    markdown_html = <<EOF.strip

<p>Link One : <a href='linktext'>yes title</a></p>

<p>Link Two : <a href='no-title'>no title</a></p>
EOF

    @book = BookBook.create(:name => 'book',
                            :content_filter => 'markdown')

    
    
    @page = @book.book_pages.create(:name => 'Test Page',
                                    :body => markdown_sample)

    @page.move_to_child_of(@book.root_node)

    @page.body_html.should == markdown_html
  end
  
  
  
end

  

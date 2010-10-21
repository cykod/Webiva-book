require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../book_spec_helper.rb"

describe BookPageVersion do
  include BookSpecHelper

  reset_domain_tables :book_books, :book_pages, :book_page_versions, :domain_files

  it 'should be able to add versions of a page' do
    @book = BookBook.create(:name => 'book of versions')
    @book.root_node.should_not be_nil

    @page = @book.book_pages.create(:name => 'Testing Versions Page')
    @page.move_to_child_of(@book.root_node)
    user = EndUser.push_target('test@webiva.com')

    @version = BookPageVersion.create(:name => "page.name", 
                                      :book_book_id => @book.id, 
                                      :book_page_id => @page.id, 
                                      :base_version_id => nil,
                                      :body => "body text",
                                      :version_status => 'unchecked',
                                      :created_by_id => user.id)

    @version.id.should_not be_nil
  end

  it "should create proper page links" do
    markdown_sample = <<EOF  

Link One : [[yes title]](linktext)  
  
Link Two : [[no title]]
EOF

    markdown_html = nil

    @book = BookBook.create(:name => 'book',
                            :content_filter => 'markdown')

    @page = @book.book_pages.create(:name => 'page.name')
    @page.move_to_child_of(@book.root_node)

    user = EndUser.push_target('test@webiva.com')

    @version = BookPageVersion.new(:name => "page.name", 
                                   :book_book_id => @book.id, 
                                   :book_page_id => @page.id, 
                                   :base_version_id => nil,
                                   :body => markdown_sample,
                                   :version_status => 'unchecked',
                                   :created_by_id => user.id)
  end
end

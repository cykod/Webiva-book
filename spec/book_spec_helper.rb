
module BookSpecHelper

  def book_fixture_file_upload(path, mime_type = nil, binary = false)
    book_fixture_path = RAILS_ROOT + '/vendor/modules/book/spec/fixtures/'
    ActionController::TestUploadedFile.new("#{book_fixture_path}#{path}", mime_type, binary)
  end

  def markdown_sample 
    return  <<EOF
Hello Nurse
==========

This is a test of the emergency broadcast system, this is only a test.

EOF
  end

  def markdown_html 
    return <<EOF.strip
<h1 id='hello_nurse'>Hello Nurse</h1>

<p>This is a test of the emergency broadcast system, this is only a test.</p>

EOF
end

  def random_string(size=12)
    (1..size).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
  end

  def chapter_book(url_scheme='flat')
    created_by_id = @myself ? @myself.id : nil

    @cb = BookBook.new(:name => 'chapter book', :created_by_id => created_by_id)
    @cb.url_scheme = url_scheme
    @cb.save

    @cb.root_node

    @page1 = @cb.book_pages.create(:name => 'chapter one', :reference => 'cp1', :created_by_id => created_by_id )
    @page1.move_to_child_of(@cb.root_node)

    @page2 = @cb.book_pages.create(:name => 'chapter two', :reference => 'cp2', :created_by_id => created_by_id)
    @page2.move_to_child_of(@cb.root_node)

    @page3 = @cb.book_pages.create(:name => 'chapter three', :reference => 'cp3', :created_by_id => created_by_id)
    @page3.move_to_child_of(@cb.root_node)

    @page4 = @cb.book_pages.create(:name => 'chapter four', :reference => 'cp4', :created_by_id => created_by_id)
    @page4.move_to_child_of(@page3)

    @page5 = @cb.book_pages.create(:name => 'chapter five', :reference => 'cp5', :created_by_id => created_by_id)
    @page5.move_to_child_of(@page4)

    # Chapter Book layout
    # <page>        <left> <right>
    # root          1      12
    # page 1        2      3
    # page 2        4      5
    # page 3        6      11
    #  * page 4     7      10
    #     * page 5  8      9

    @page1.reload
    @page2.reload
    @page3.reload
    @page4.reload
    @page5.reload
    @cb = BookBook.find @cb.id

    @cb
  end

  def flat_book(url_scheme='flat')
    created_by_id = @myself ? @myself.id : nil

    @flatbook =  BookBook.new(:name => 'flatbook', :created_by_id => created_by_id)
    @flatbook.book_type = 'flat' # attr_protected
    @flatbook.url_scheme = url_scheme
    @flatbook.save

    @flatpage1 = @flatbook.book_pages.create(:name => 'a flat one', :reference => 'flat1', :created_by_id => created_by_id)
    @flatpage2 = @flatbook.book_pages.create(:name => 'b flat two', :reference => 'flat2', :created_by_id => created_by_id)
    @flatpage3 = @flatbook.book_pages.create(:name => 'c flat three', :reference => 'flat3', :created_by_id => created_by_id)
    @flatpage4 = @flatbook.book_pages.create(:name => 'd flat four', :reference => 'flat4', :created_by_id => created_by_id)
    @flatpage5 = @flatbook.book_pages.create(:name => 'e flat five', :reference => 'flat5', :created_by_id => created_by_id)

    @flatbook
  end
end

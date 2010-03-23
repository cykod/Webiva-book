module BookSpecHelper

  def create_end_user(email='test@webiva.com', options={:first_name => 'Test', :last_name => 'User'})
    EndUser.push_target(email, options)
  end

  def create_editor(email='test@webiva.com', options={:first_name => 'Editor', :last_name => "User"})
    EndUser.push_target(email,options)
  end
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
  def chapter_book
    mock_editor
    @rand_name = random_string

    @cb = BookBook.create(:name => 'chapter book', :created_by_id => @myself.id)
    @page1 = @cb.book_pages.create(:name => 'chapter one', :created_by_id => @myself.id )
    @page1.move_to_child_of(@cb.root_node)
    @page2 = @cb.book_pages.create(:name => 'chapter two' , :created_by_id => @myself.id)
    @page2.move_to_child_of(@cb.root_node)
    @page3 = @cb.book_pages.create(:name => 'chapter three', :created_by_id => @myself.id)
    @page3.move_to_child_of(@cb.root_node)
    @page4 = @cb.book_pages.create(:name => 'chapter four' , :created_by_id => @myself.id)
    @page4.move_to_child_of(@cb.root_node)
    @page5 = @cb.book_pages.create(:name => 'chapter five' , :created_by_id => @myself.id)
    @page5.move_to_child_of(@cb.root_node)
  end


  def flat_book
    mock_editor

    @rand_name = random_string    
    @flatbook =  BookBook.create(:book_type => 'flat', :name => 'flatbook', :created_by_id => @myself.id)
    @page1 = @flatbook.book_pages.create(:name => 'a flat one' , :created_by_id => @myself.id)
    @page2 = @flatbook.book_pages.create(:name => 'b flat two' , :created_by_id => @myself.id)
    @page3 = @flatbook.book_pages.create(:name => 'c flat three', :created_by_id => @myself.id)
    @page4 = @flatbook.book_pages.create(:name => 'd flat four' , :created_by_id => @myself.id)
    @page5 = @flatbook.book_pages.create(:name => 'e flat five' , :created_by_id => @myself.id)
  end


  def create_book(name='Test Book')
    BookBook.create(name, :created_by_id => @myself.id)
  end

  def create_book_page(page=nil,options={:name => 'Page', :body => markdown_sample})    
    BookPage.create({:name =>name}.merge(options) )
  end
  
end

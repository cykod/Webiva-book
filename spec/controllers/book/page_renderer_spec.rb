require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Book::PageRenderer, :type => :controller do
  
  controller_name :page

  integrate_views

  reset_domain_tables :book_books, :book_pages, :book_page_versions, :page_paragraphs, :site_nodes
  
  # create a dummy book & pages
  before(:each) do
    
    mock_user
  
    @chapterbook = BookBook.create(:name => 'chapter book', :book_type => 'chapter')
    @page1 = @chapterbook.book_pages.create(:name => 'chapter one' , :body => "this is a test to see if we suck" )
    @page1.move_to_child_of(@chapterbook.root_node)
    @page2 = @chapterbook.book_pages.create(:name => 'chapter two' )
    @page2.move_to_child_of(@chapterbook.root_node)
    @page3 = @chapterbook.book_pages.create(:name => 'chapter three', :published => false)
    @page3.move_to_child_of(@chapterbook.root_node)
    @page4 = @chapterbook.book_pages.create(:name => 'chapter four' )
    @page4.move_to_child_of(@chapterbook.root_node)
    @page5 = @chapterbook.book_pages.create(:name => 'chapter five' )
    @page5.move_to_child_of(@chapterbook.root_node)

    @page6 = @chapterbook.book_pages.create(:name => 'chapter six' , :published => false)
    @page6.move_to_child_of(@page5)
    @page7 = @chapterbook.book_pages.create(:name => 'chapter seven')
    @page7.move_to_child_of(@page5)

    @page8 = @chapterbook.book_pages.create(:name => 'chapter eight' )
    @page8.move_to_child_of(@page7)
    @chapterbook.root_node.reload
  end
  describe 'using page connection' do
    
    it 'should find a book by page connection' do

      @rnd = build_renderer('/page', '/book/page/content', {}, {:book => [ :book_id, @chapterbook.id ]})
      BookBook.should_receive( :find_by_id ).with(@chapterbook.id).and_return(@chapterbook)
      @rnd.should_render_feature( :book_page_content )
      renderer_get( @rnd )
    end

    it 'should not display unpublished pages' do

      @rnd = build_renderer('/page', '/book/page/chapters', {}, {:book => [ :book_id, @chapterbook.id ]})
      BookBook.should_receive( :find_by_id ).with(@chapterbook.id).and_return(@chapterbook)
      @rnd.should_render_feature( :menu )
      renderer_get( @rnd )
      @rnd.renderer_feature_data[:menu][2][:title].should == 'chapter four'
    end

    it 'should display a chapter list based on id ' do

      @rnd = build_renderer('/page', '/book/page/chapters', {:levels => 0}, {:book => [ :book_id, @chapterbook.id ]})
      BookBook.should_receive( :find_by_id ).with(@chapterbook.id).and_return(@chapterbook)
      @rnd.should_render_feature( :menu )
      renderer_get( @rnd )
      
      @rnd.renderer_feature_data[:menu][0][:title].should == 'chapter one'
      @rnd.renderer_feature_data[:menu][-1][:title].should == 'chapter five'
    end
    
    it 'should  display nested menus if requested, by default, only the top level id displayed' do
      @rnd = build_renderer('/page', '/book/page/chapters', {:levels => 2}, {:book => [ :book_id, @chapterbook.id ]})
      BookBook.should_receive( :find_by_id ).with(@chapterbook.id).and_return(@chapterbook)
      @rnd.should_render_feature( :menu )
      renderer_get( @rnd )
      
      @rnd.renderer_feature_data[:menu][0][:title].should == 'chapter one'
      @rnd.renderer_feature_data[:menu][1][:title].should == 'chapter two'
      @rnd.renderer_feature_data[:menu][2][:title].should == 'chapter four'
      @rnd.renderer_feature_data[:menu][3][:title].should == 'chapter five'
      @rnd.renderer_feature_data[:menu][3][:menu][0][:title].should == 'chapter seven'

      # The book created above has 3 levels in the nested tree.  This test is checking to see that only 2 levels are being rendered.  This block steps through the the menu level 1 searching for menu level 2, and in menu level 2 another block verifies that menu level 3 is nil
      @rnd.renderer_feature_data[:menu].each do |menu|
        if menu[:menu]
          menu[:menu].each {|submenu| submenu[:menu].should be_nil }
          
        end    
      end
    end
  end  
  describe 'wiki editing' do

    it 'should save page versions edited by a user' do
      @content_page = SiteVersion.default.root_node.add_subpage 'content_book'
      @rnd = build_renderer('/page', '/book/page/wiki_editor', 
                            {:allow_create => true,
                              :book_id => @chapterbook.id, 
                              :content_page_id => @content_page.id
                            },
                            {:book => [ :book_id, @chapterbook.id ],
                             :flat_chapter =>[ :chapter_id ,@page1.url ]
                            })
     
      BookBook.should_receive( :find_by_id ).with(@chapterbook.id).and_return(@chapterbook)

      @page1.book_page_versions.count.should == 1

      renderer_post( @rnd, 
            :commit => 'Submit',
            :page_versions => {
              :body => 'content book page version, new page'})

      # Need to add test back in
      @page1.reload
      @page1.book_page_versions.count.should == 2

    end
    
  end
  
end


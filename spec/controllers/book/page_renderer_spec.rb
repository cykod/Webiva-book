require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../../book_spec_helper.rb"

describe Book::PageRenderer, :type => :controller do
  include BookSpecHelper

  controller_name :page

  integrate_views

  reset_domain_tables :book_books, :book_pages, :book_page_versions, :page_paragraphs, :site_nodes, :end_users
  
  # create a dummy book & pages
  before(:each) do
    chapter_book
    mock_user
  
    
  end
  describe 'using page connection' do
    
    it 'should find a book by page connection' do

      @rnd = build_renderer('/page', '/book/page/content', {}, {:book => [ :book_id, @cb.id ]})
      BookBook.should_receive( :find_by_id ).with(@cb.id).and_return(@cb)
      @rnd.should_render_feature( :book_page_content )
      renderer_get( @rnd )
    end

    it 'should not display unpublished pages' do

      @rnd = build_renderer('/page', '/book/page/chapters', {}, {:book => [ :book_id, @cb.id ]})
      BookBook.should_receive( :find_by_id ).with(@cb.id).and_return(@cb)
      @rnd.should_render_feature( :menu )
      renderer_get( @rnd )
      @rnd.renderer_feature_data[:menu][2][:title].should == @page3.name
    end

    it 'should display a chapter list based on id ' do

      @rnd = build_renderer('/page', '/book/page/chapters', {:levels => 0}, {:book => [ :book_id, @cb.id ]})
      BookBook.should_receive( :find_by_id ).with(@cb.id).and_return(@cb)
      @rnd.should_render_feature( :menu )
      renderer_get( @rnd )
      
      @rnd.renderer_feature_data[:menu][0][:title].should == @page1.name
      @rnd.renderer_feature_data[:menu][-1][:title].should == @page5.name
    end
    
    it 'should  display nested menus if requested, by default, only the top level id displayed' do
      @rnd = build_renderer('/page', '/book/page/chapters', {:levels => 2}, {:book => [ :book_id, @cb.id ]})
      BookBook.should_receive( :find_by_id ).with(@cb.id).and_return(@cb)
      @rnd.should_render_feature( :menu )
      renderer_get( @rnd )
      
      @rnd.renderer_feature_data[:menu][0][:title].should == @page1.name
      @rnd.renderer_feature_data[:menu][1][:title].should == @page2.name
      @rnd.renderer_feature_data[:menu][2][:title].should == @page3.name
      @rnd.renderer_feature_data[:menu][3][:title].should == @page4.name

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
                              :book_id => @cb.id, 
                              :content_page_id => @content_page.id
                            },
                            {:book => [ :book_id, @cb.id ],
                             :flat_chapter =>[ :chapter_id ,@page1.url ]
                            })
     
      BookBook.should_receive( :find_by_id ).with(@cb.id).and_return(@cb)

      @page1.book_page_versions.count.should == 1

      renderer_post( @rnd, 
            :commit => 'Submit',
            :page_versions => {
              :body => 'content book page version, new page'})

      @page1.reload
      @page1.book_page_versions.count.should == 2

    end

    it 'should save the correct user as editor if one available' do
      @u1 = EndUser.push_target('test11111@webiva.com')
      @u2 = EndUser.push_target('test22222@webiva.com')
      

      ## Create a page as one user, and update that page as another user.
      @content_page = SiteVersion.default.root_node.add_subpage 'content_book'
      
      @bb = BookBook.new(:name => "Test Username Updates")
      @bb.save
      @pg = @bb.book_pages.create(:name => "init page should have user 1", :editor => @u1.id)
    
      @pg.body = "user should be u1.id"
      @pg.editor = @u1.id
      @pg.save

      @pg.book_page_versions[0].created_by_id.should == @u1.id
      
      @rnd = build_renderer('/page', '/book/page/wiki_editor',
                            {:allow_create => true,
                              :book_id => @bb.id,
                              :content_page_id => @content_page.id,
                              :allow_auto_version => false
                            },
                            {:book => [ :book_id, @bb.id ],
                              :flat_chapter =>[ :chapter_id ,@pg.url ]
                            })

      BookBook.should_receive( :find_by_id ).with(@bb.id).and_return(@bb)
      @pg.book_page_versions.count.should == 2
      
      
      renderer_post( @rnd, :commit => "Submit", :path => [@pg.id], :page_versions => {:body => "content book page version orig page", :editor => @u2.id})

      @pg.book_page_versions[1].created_by_id.should == @u1.id

    end     
  end
  describe 'Auto Publishing Wiki' do

    def build_auto_publish(url,opts={}) 
      @rnd = build_renderer('/page', '/book/page/wiki_editor', {:allow_create => true, :book_id => @bb.id, :book_page_id => @pg.id, :content_page_id => @content_page.id, :allow_auto_version => true }.merge(opts), {:book => [ :book_id, @bb.id ], :flat_chapter =>[ :chapter_id ,url ] })
    end
    before(:each) do
      @u1 = EndUser.push_target('test11111@webiva.com')
      @content_page = SiteVersion.default.root_node.add_subpage 'content_book'
      @bb = BookBook.create(:name => "Test AutoPublish Versions")
      @pg = @bb.book_pages.create(:name => "Page Save", :editor => @u1.id)
      @pg.move_to_child_of(@bb.root_node)
      @pg.body = "Auto Publish Page Body 1st"
      @pg.editor = @u1.id
      @pg.save
    end
   
    
    it 'should create a version of an auto-published updated page' do
      build_auto_publish(@pg.url, {:allow_auto_version => true}) 
      BookBook.should_receive( :find_by_id ).with(@bb.id).and_return(@bb)
      @pg.book_page_versions.length.should == 2
      renderer_post( @rnd, :commit => "Submit", :path => [@bb.name, @rnd.site_node.node_path, @pg.name], :book_page_id => @pg.id, :page_versions => {:body => "Auto Publish Page Body Now 2nd"}, :editor => @u1.id)
      @pg.reload
      @pg.book_page_versions.count.should == 3
    end
    it 'should create a version of an auto-published new page' do
      build_auto_publish("newpage", {:allow_auto_version => true}) 
      BookBook.should_receive( :find_by_id ).with(@bb.id).and_return(@bb)
      renderer_post( @rnd, :commit => "Submit", :path => [@bb.name, @rnd.site_node.node_path, "newpage"], :book_page_id => "", :page_versions => {:body => "Auto Publish Page Body 1st"}, :editor => @u1.id)

      @new_pg = @bb.book_pages.find_by_name("newpage")
      @new_pg.book_page_versions.count.should == 1
    end
    it 'should create a version of a non-auto-published updated page' do
      build_auto_publish(@pg.url, {:allow_auto_version => false}) 
      BookBook.should_receive( :find_by_id ).with(@bb.id).and_return(@bb)
      @pg.book_page_versions.length.should == 2
      renderer_post( @rnd, :commit => "Submit", :path => [@bb.name, @rnd.site_node.node_path, @pg.name], :book_page_id => @pg.id, :page_versions => {:body => "Auto Publish Page Body Now 2nd"}, :editor => @u1.id)
      @pg.reload
      @pg.book_page_versions.count.should == 3
    end
    it 'should create a version of a non-auto-published new page' do
      build_auto_publish("newpage", {:allow_auto_version => false}) 
      BookBook.should_receive( :find_by_id ).with(@bb.id).and_return(@bb)
      renderer_post( @rnd, :commit => "Submit", :path => [@bb.name, @rnd.site_node.node_path, "newpage"], :book_page_id => "", :page_versions => {:body => "Auto Publish Page Body 1st"}, :editor => @u1.id)
      @new_pg = @bb.book_pages.find_by_name("newpage")
      @new_pg.book_page_versions.count.should == 1

    end

  end
end

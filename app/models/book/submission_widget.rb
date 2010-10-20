
class Book::SubmissionWidget < Dashboard::WidgetBase
  widget :submissions, :name => "Book: Display Recent Wiki Edits", :title => "Recent Wiki Edits", :permission => :book_manage

  def submissions
    set_icon 'book_icon.png'
    set_title_link url_for(:controller => 'content')
    @submissions = BookPageVersion.find(:all, :include => [:created_by, :book_book], :conditions => ['version_status = "submitted"'], :limit => options.count)
    render_widget :partial => '/book/submission_widget/submissions', :locals => {:submissions => @submissions , :options => options}
  end

  class SubmissionsOptions < HashModel
    attributes :count => 10

    integer_options :count
    validates_numericality_of :count

    options_form(
                 fld(:count, :text_field, :label => "Number submissions displayed")
                 )
  end
end

class RevisionDiff < ActiveRecord::Migration
  def self.up
    add_column :book_page_versions, :body_diff, :text

  end

  def self.down
    remove_column :book_page_versions, :body_diff, :text
  end
end

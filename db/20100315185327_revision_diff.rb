class RevisionDiff < ActiveRecord::Migration
  def self.up
    add_column :book_page_versions,:base_version_id, :int
    remove_column :book_page_versions, :body_html

  end

  def self.down
    remove_column :book_page_versions, :base_version_id
    add_column :book_page_versions, :body_html, :text
  end
end

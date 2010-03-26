class RevisionDiff < ActiveRecord::Migration
  def self.up
    change_column :book_page_versions, :body, :integer
    rename_column :book_page_versions, :body, :base_version_id
    add_column :book_page_versions, :body_diff, :text
    remove_column :book_page_versions, :body_html

  end

  def self.down
    rename_column :book_page_versions, :base_version_id, :body
    change_column :book_page_versions, :body, :text
    remove_column :book_page_versions, :body_diff, :text
    add_column :book_page_versions, :body_html, :text
  end
end
